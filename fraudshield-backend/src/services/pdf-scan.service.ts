// eslint-disable-next-line @typescript-eslint/no-var-requires
const pdfParse = require('pdf-parse');
import crypto from 'crypto';
import { createClient } from 'redis';

const CACHE_TTL_SECONDS = 30 * 60; // 30 minutes

// ── Scam Keyword Database ────────────────────────────────────────────────────

const SCAM_PHRASE_PATTERNS: Array<{ pattern: RegExp; label: string; score: number }> = [
    // ── Fake Invoice / Finance ──
    { pattern: /total (due|amount|outstanding|payable).{0,30}(rm|myr|\$|usd)/i, label: 'Fake invoice amount', score: 40 },
    { pattern: /(overdue|outstanding (balance|payment)|final (notice|warning))/i, label: 'Overdue payment pressure', score: 35 },
    { pattern: /(penalty|fine|surcharge|late (fee|charge)).{0,30}(rm|myr|\$)/i, label: 'Penalty/fine threat', score: 40 },
    { pattern: /pay (immediately|now|within \d+ (day|hour|jam))/i, label: 'Urgent payment demand', score: 35 },
    { pattern: /(bank transfer|wire transfer|online transfer).{0,40}(account number|nombor akaun)/i, label: 'Suspicious transfer instruction', score: 45 },

    // ── Legal / Authority Impersonation ──
    { pattern: /(lhdn|hasil|irb|kementerian|jabatan (kastam|imigresen)|pdrm|sprm|mahkamah)/i, label: 'Malaysian authority impersonation', score: 50 },
    { pattern: /(court order|saman|waran tangkap|notis rasmi|official notice)/i, label: 'Legal threat impersonation', score: 55 },
    { pattern: /(tax (arrears|evasion|audit|investigation)|cukai tertunggak)/i, label: 'Tax fraud claim', score: 50 },
    { pattern: /(arrest warrant|criminal investigation|seized|dirampas)/i, label: 'Criminal threat', score: 60 },

    // ── Investment / Prize Scam ──
    { pattern: /(guaranteed (return|profit|income)|dijamin (untung|keuntungan))/i, label: 'Guaranteed return claim', score: 50 },
    { pattern: /(lucky (draw|winner)|tahniah.{0,30}(menang|dipilih))/i, label: 'Lottery winner claim', score: 50 },
    { pattern: /(claim.{0,20}(prize|reward|hadiah|wang).{0,20}(within|dalam|sebelum))/i, label: 'Prize claim with deadline', score: 55 },

    // ── Credential Harvesting ──
    { pattern: /(enter|provide|submit).{0,30}(otp|pin|password|ic number|nombor ic|kad pengenalan)/i, label: 'Credential harvesting attempt', score: 60 },
    { pattern: /(scan.{0,20}qr|sila imbas).{0,50}(verify|confirm|login|log masuk)/i, label: 'QR phishing in document', score: 55 },
];

const URGENCY_PATTERNS: Array<{ pattern: RegExp; label: string }> = [
    { pattern: /\b(urgent|segera|immediately|within 24|within 48|dalam (24|48) jam)\b/i, label: 'Urgency language' },
    { pattern: /\b(do not ignore|jangan abaikan|failure to (comply|respond)|tidak bertindak balas)\b/i, label: 'Non-compliance threat' },
    { pattern: /!{2,}/, label: 'Excessive exclamation marks' },
];

// URLs embedded in PDF text — high risk in scam docs
const URL_PATTERN = /https?:\/\/[^\s"'<>\]]{10,}/gi;

// ── Suspicious Metadata Indicators ──────────────────────────────────────────

const SUSPICIOUS_CREATOR_APPS = [
    'unknown', 'none', 'libre office', 'openoffice', // Legitimate but sometimes used
];

export interface PdfScanResult {
    score: number;
    level: 'low' | 'medium' | 'high' | 'critical';
    reasons: string[];
    extractedLinks: string[];
    metadata: {
        title?: string;
        author?: string;
        creator?: string;
        pageCount?: number;
    };
    sha256: string;
    fromCache?: boolean;
    checkedAt: string;
}

export class PdfScanService {
    static async analyze(buffer: Buffer): Promise<PdfScanResult> {
        // 1. SHA-256 fingerprint
        const sha256 = crypto.createHash('sha256').update(buffer).digest('hex');

        // 2. Check Redis cache
        let redisClient: ReturnType<typeof createClient> | null = null;
        try {
            const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
            redisClient = createClient({ url: redisUrl });
            await redisClient.connect();
            const cached = await redisClient.get(`pdf:${sha256}`);
            if (cached) {
                await redisClient.disconnect();
                return { ...JSON.parse(String(cached)), fromCache: true };
            }
        } catch {
            redisClient = null;
        }

        // 3. Parse PDF using pdf-parse v1.x simple function API
        let text = '';
        let numpages = 0;
        let info: Record<string, any> = {};

        try {
            const pdfData = await pdfParse(buffer, { max: 10 });
            text = pdfData.text || '';
            numpages = pdfData.numpages || 0;
            info = pdfData.info || {};
        } catch (err: any) {
            console.error('[PdfScanService] Error parsing PDF:', err.message);
            const result: PdfScanResult = {
                score: 30,
                level: 'medium',
                reasons: [`⚠️ PDF could not be parsed: ${err.message || 'unknown error'}`],
                extractedLinks: [],
                metadata: {},
                sha256,
                checkedAt: new Date().toISOString(),
            };
            return result;
        }

        // 4. Scam phrase matching
        let score = 0;
        const reasons: string[] = [];
        const matchedPhrases: string[] = [];

        for (const { pattern, label, score: weight } of SCAM_PHRASE_PATTERNS) {
            const match = text.match(pattern);
            if (match) {
                score += weight;
                reasons.push(`⚠️ ${label}`);
                if (match[0]) matchedPhrases.push(match[0].trim().substring(0, 60));
            }
        }

        // 5. Urgency amplifiers
        let urgencyCount = 0;
        for (const { pattern, label } of URGENCY_PATTERNS) {
            if (pattern.test(text)) {
                urgencyCount++;
                reasons.push(`⚠️ ${label}`);
            }
        }
        if (score > 0 && urgencyCount > 0) score += Math.min(urgencyCount * 15, 30);

        // 6. Embedded URLs
        const extractedLinks: string[] = [...new Set((text.match(URL_PATTERN) ?? []) as string[])];
        if (extractedLinks.length > 0) {
            reasons.push(`🔗 ${extractedLinks.length} link(s) embedded in document`);
            if (score > 20) score += 15; // Links + other signals = higher risk
        }

        // 7. Suspicious metadata
        const creator = (info.Creator || info.Producer || '').toLowerCase();
        if (creator && SUSPICIOUS_CREATOR_APPS.some(app => creator.includes(app))) {
            // Not an automatic flag, just note it
            reasons.push(`ℹ️ Created with: ${info.Creator || info.Producer}`);
        }

        // 8. VirusTotal hash check (non-blocking)
        const vtKey = process.env.VIRUSTOTAL_API_KEY;
        if (vtKey) {
            try {
                const vtResult = await Promise.race([
                    PdfScanService._checkVirusTotalHash(sha256, vtKey),
                    new Promise<null>((r) => setTimeout(() => r(null), 4000)),
                ]);
                if (vtResult && vtResult.malicious > 0) {
                    score = Math.max(score, 85);
                    reasons.unshift(`🚨 Hash flagged by ${vtResult.malicious} VirusTotal engine(s)`);
                }
            } catch { /* non-fatal */ }
        }

        if (score === 0) {
            reasons.push('✅ No suspicious content detected in document');
        }

        const finalScore = Math.min(score, 100);
        const level = PdfScanService._getLevel(finalScore);

        const result: PdfScanResult = {
            score: finalScore,
            level,
            reasons: [...new Set(reasons)],
            extractedLinks,
            metadata: {
                title: info.Title,
                author: info.Author,
                creator: info.Creator || info.Producer,
                pageCount: numpages,
            },
            sha256,
            checkedAt: new Date().toISOString(),
        };

        // Cache result
        if (redisClient) {
            try {
                await redisClient.set(`pdf:${sha256}`, JSON.stringify(result), { EX: CACHE_TTL_SECONDS });
                await redisClient.disconnect();
            } catch { /* non-fatal */ }
        }

        return result;
    }

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
