import crypto from 'crypto';
import { createClient } from 'redis';
import yauzl from 'yauzl';
import { Readable } from 'stream';

const CACHE_TTL_SECONDS = 30 * 60; // 30 minutes
const APK_MAGIC = Buffer.from([0x50, 0x4b, 0x03, 0x04]); // PK\x03\x04 ZIP header

// ── Dangerous Android Permissions ───────────────────────────────────────────
const DANGEROUS_PERMISSIONS: Record<string, { label: string; score: number }> = {
    'android.permission.READ_SMS': { label: 'Read SMS messages', score: 30 },
    'android.permission.RECEIVE_SMS': { label: 'Intercept incoming SMS', score: 35 },
    'android.permission.SEND_SMS': { label: 'Send SMS messages', score: 25 },
    'android.permission.READ_CALL_LOG': { label: 'Read call history', score: 20 },
    'android.permission.PROCESS_OUTGOING_CALLS': { label: 'Intercept outgoing calls', score: 30 },
    'android.permission.RECORD_AUDIO': { label: 'Record audio/microphone', score: 25 },
    'android.permission.CAMERA': { label: 'Access camera', score: 15 },
    'android.permission.READ_CONTACTS': { label: 'Read contacts list', score: 20 },
    'android.permission.BIND_DEVICE_ADMIN': { label: 'Device Administrator access', score: 50 },
    'android.permission.SYSTEM_ALERT_WINDOW': { label: 'Screen Overlay (clickjacking risk)', score: 40 },
    'android.permission.BIND_ACCESSIBILITY_SERVICE': { label: 'Accessibility Service (screen reader)', score: 45 },
    'android.permission.GET_TASKS': { label: 'View running applications', score: 15 },
    'android.permission.MOUNT_UNMOUNT_FILESYSTEMS': { label: 'Access filesystem', score: 20 },
    'android.permission.INSTALL_PACKAGES': { label: 'Install additional apps', score: 40 },
    'android.permission.REQUEST_INSTALL_PACKAGES': { label: 'Request to install APKs', score: 30 },
    'android.permission.READ_PHONE_STATE': { label: 'Read device IMEI/identity', score: 20 },
    'android.permission.CHANGE_NETWORK_STATE': { label: 'Modify network settings', score: 15 },
    'android.permission.DISABLE_KEYGUARD': { label: 'Disable screen lock', score: 40 },
    'android.permission.WAKE_LOCK': { label: 'Prevent phone from sleeping', score: 10 },
};

// High-risk permission combos that together indicate banking trojan, stalkerware, RAT
const HIGH_RISK_COMBOS: Array<{ perms: string[]; label: string; score: number }> = [
    {
        perms: ['android.permission.READ_SMS', 'android.permission.SYSTEM_ALERT_WINDOW', 'android.permission.BIND_ACCESSIBILITY_SERVICE'],
        label: '🚨 Banking trojan permission combo detected (SMS interception + Overlay + Accessibility)',
        score: 60,
    },
    {
        perms: ['android.permission.BIND_DEVICE_ADMIN', 'android.permission.INSTALL_PACKAGES'],
        label: '🚨 RAT/Stalkerware combo: Device Admin + Install Packages',
        score: 55,
    },
    {
        perms: ['android.permission.RECORD_AUDIO', 'android.permission.CAMERA', 'android.permission.READ_CONTACTS'],
        label: '⚠️ Surveillance app combo: Audio + Camera + Contacts',
        score: 35,
    },
];

// Typosquatted app package names that impersonate legitimate Malaysian banking/gov apps
const IMPERSONATION_PATTERNS = [
    { pattern: /^(?!com\.(maybank|cimbclicks|public\.com|rhb|affinbank)).*may.?bank/i, label: 'Maybank impersonation' },
    { pattern: /^(?!com\.cimbclicks).*cimb/i, label: 'CIMB impersonation' },
    { pattern: /^(?!com\.rhb).*rhb/i, label: 'RHB impersonation' },
    { pattern: /^(?!my\.gov\.|com\.malaysia).*myeg|epf|kwsp|lhdn|hasil/i, label: 'Gov/Bank impersonation' },
];

export interface ApkScanResult {
    score: number;
    level: 'low' | 'medium' | 'high' | 'critical';
    reasons: string[];
    packageName?: string;
    dangerousPermissions: string[];
    permissionCount: number;
    fileEntropy: number;
    sha256: string;
    virusTotalDetections?: number;
    fromCache?: boolean;
    checkedAt: string;
}

export class ApkScanService {
    static async analyze(buffer: Buffer, filename: string): Promise<ApkScanResult> {
        // 1. SHA-256 fingerprint
        const sha256 = crypto.createHash('sha256').update(buffer).digest('hex');

        // 2. Check Redis cache
        let redisClient: ReturnType<typeof createClient> | null = null;
        try {
            const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
            redisClient = createClient({ url: redisUrl });
            await redisClient.connect();
            const cached = await redisClient.get(`apk:${sha256}`);
            if (cached) {
                await redisClient.disconnect();
                return { ...JSON.parse(String(cached)), fromCache: true };
            }
        } catch {
            redisClient = null;
        }

        // 3. Validate APK magic bytes (PK header)
        if (!buffer.slice(0, 4).equals(APK_MAGIC)) {
            const result: ApkScanResult = {
                score: 20,
                level: 'low',
                reasons: ['⚠️ File does not appear to be a valid APK (invalid header)'],
                dangerousPermissions: [],
                permissionCount: 0,
                fileEntropy: 0,
                sha256,
                checkedAt: new Date().toISOString(),
            };
            return result;
        }

        // 4. Calculate file entropy
        const entropy = ApkScanService._calcEntropy(buffer);

        // 5. Extract manifest data from APK (ZIP)
        const manifestData = await ApkScanService._extractManifestStrings(buffer);

        // 6. Score based on findings
        let score = 0;
        const reasons: string[] = [];
        const dangerousPermissions: string[] = [];

        // Entropy check — high entropy indicates packed/obfuscated binary
        if (entropy > 7.5) {
            score += 25;
            reasons.push(`⚠️ High file entropy (${entropy.toFixed(2)}) — possible obfuscation/packing`);
        } else if (entropy > 7.0) {
            score += 10;
        }

        // Permission analysis
        const allPerms = manifestData.permissions;
        let permScore = 0;
        for (const perm of allPerms) {
            const danger = DANGEROUS_PERMISSIONS[perm];
            if (danger) {
                dangerousPermissions.push(danger.label);
                permScore += danger.score;
            }
        }

        // Cap permission contribution
        if (permScore > 0) {
            score += Math.min(permScore, 60);
            reasons.push(...dangerousPermissions.map(p => `⚠️ Dangerous permission: ${p}`));
        }

        // High-risk combos
        for (const combo of HIGH_RISK_COMBOS) {
            if (combo.perms.every(p => allPerms.includes(p))) {
                score += combo.score;
                reasons.unshift(combo.label);
            }
        }

        // Permission count
        if (allPerms.length > 20) {
            score += 20;
            reasons.push(`⚠️ Excessive permissions: ${allPerms.length} requested (>20 is suspicious)`);
        } else if (allPerms.length > 15) {
            score += 10;
            reasons.push(`⚠️ High permission count: ${allPerms.length} requested`);
        }

        // Package name impersonation
        if (manifestData.packageName) {
            for (const { pattern, label } of IMPERSONATION_PATTERNS) {
                if (pattern.test(manifestData.packageName)) {
                    score += 50;
                    reasons.unshift(`🚨 Package name impersonates a known bank/gov app: ${label}`);
                    break;
                }
            }
        }

        // 7. VirusTotal hash check (non-blocking)
        let vtDetections: number | undefined;
        const vtKey = process.env.VIRUSTOTAL_API_KEY;
        if (vtKey) {
            try {
                const vtResult = await Promise.race([
                    ApkScanService._checkVirusTotalHash(sha256, vtKey),
                    new Promise<null>((r) => setTimeout(() => r(null), 4000)),
                ]);
                if (vtResult && vtResult.malicious > 0) {
                    vtDetections = vtResult.malicious;
                    score = Math.max(score, 85);
                    reasons.unshift(`🚨 Flagged as malicious by ${vtDetections} VirusTotal engine(s)`);
                }
            } catch { /* non-fatal */ }
        }

        if (score === 0) {
            reasons.push('✅ No dangerous permissions or known malware signatures detected');
        }

        const finalScore = Math.min(score, 100);
        const level = ApkScanService._getLevel(finalScore);

        const result: ApkScanResult = {
            score: finalScore,
            level,
            reasons: [...new Set(reasons)],
            packageName: manifestData.packageName,
            dangerousPermissions,
            permissionCount: allPerms.length,
            fileEntropy: parseFloat(entropy.toFixed(2)),
            sha256,
            virusTotalDetections: vtDetections,
            checkedAt: new Date().toISOString(),
        };

        // Cache result
        if (redisClient) {
            try {
                await redisClient.set(`apk:${sha256}`, JSON.stringify(result), { EX: CACHE_TTL_SECONDS });
                await redisClient.disconnect();
            } catch { /* non-fatal */ }
        }

        return result;
    }

    // ── Extract strings from APK ZIP to find manifest permissions ─────────────

    private static async _extractManifestStrings(buffer: Buffer): Promise<{ packageName?: string; permissions: string[] }> {
        return new Promise((resolve) => {
            const permissions: string[] = [];
            let packageName: string | undefined;

            try {
                yauzl.fromBuffer(buffer, { lazyEntries: true }, (err, zipfile) => {
                    if (err || !zipfile) return resolve({ permissions });

                    zipfile.readEntry();
                    zipfile.on('entry', (entry) => {
                        if (entry.fileName === 'AndroidManifest.xml') {
                            zipfile.openReadStream(entry, (streamErr, stream) => {
                                if (streamErr || !stream) {
                                    zipfile.readEntry();
                                    return;
                                }

                                const chunks: Buffer[] = [];
                                stream.on('data', (chunk) => chunks.push(chunk as Buffer));
                                stream.on('end', () => {
                                    const manifestBuffer = Buffer.concat(chunks);
                                    // Extract permission strings via regex on binary XML
                                    // Binary AXML contains permission strings as UTF-16/UTF-8
                                    const manifestStr = manifestBuffer.toString('utf8', 0, Math.min(manifestBuffer.length, 65536));

                                    // Extract all permission strings by searching for the well-known prefix
                                    const permMatches = manifestStr.match(/android\.permission\.[A-Z_]+/g) ?? [];
                                    permissions.push(...permMatches);

                                    // Try to extract package name from common patterns
                                    const pkgMatch = manifestStr.match(/package(?:Name)?[=\s:"]*([a-z][a-z0-9_.]{4,})/i);
                                    if (pkgMatch) packageName = pkgMatch[1];

                                    zipfile.close();
                                    resolve({ packageName, permissions: [...new Set(permissions)] });
                                });
                            });
                        } else {
                            zipfile.readEntry();
                        }
                    });

                    zipfile.on('end', () => resolve({ packageName, permissions: [...new Set(permissions)] }));
                    zipfile.on('error', () => resolve({ packageName, permissions: [...new Set(permissions)] }));
                });
            } catch {
                resolve({ packageName, permissions: [] });
            }
        });
    }

    // ── Shannon Entropy ──────────────────────────────────────────────────────

    private static _calcEntropy(buffer: Buffer): number {
        const freq: number[] = new Array(256).fill(0);
        for (const byte of buffer) freq[byte]++;
        const len = buffer.length;
        let entropy = 0;
        for (const count of freq) {
            if (count === 0) continue;
            const p = count / len;
            entropy -= p * Math.log2(p);
        }
        return entropy;
    }

    // ── VirusTotal ───────────────────────────────────────────────────────────

    private static async _checkVirusTotalHash(hash: string, apiKey: string): Promise<{ malicious: number } | null> {
        try {
            const response = await fetch(`https://www.virustotal.com/api/v3/files/${hash}`, {
                headers: { 'x-apikey': apiKey },
            });
            if (!response.ok) return null;
            const data = await response.json() as any;
            const stats = data?.data?.attributes?.last_analysis_stats;
            if (!stats) return null;
            return { malicious: (stats.malicious ?? 0) + (stats.suspicious ?? 0) };
        } catch {
            return null;
        }
    }

    private static _getLevel(score: number): 'low' | 'medium' | 'high' | 'critical' {
        if (score >= 80) return 'critical';
        if (score >= 55) return 'high';
        if (score >= 30) return 'medium';
        return 'low';
    }
}
