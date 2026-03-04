import { createClient } from 'redis';
import { validateSafeUrl } from '../utils/ssrf';

const SAFE_BROWSING_URL = 'https://safebrowsing.googleapis.com/v4/threatMatches:find';
const VIRUSTOTAL_URL = 'https://www.virustotal.com/api/v3/urls';

const MAX_REDIRECT_HOPS = 10;
const HOP_TIMEOUT_MS = 5000;
const CACHE_TTL_SECONDS = 15 * 60; // 15 minutes

// Known URL shorteners — these are a quishing red flag in QR codes
const QR_SHORTENERS = [
    'bit.ly', 'tinyurl.com', 'goo.gl', 't.co', 'is.gd', 'buff.ly', 'ow.ly',
    'rb.gy', 'cutt.ly', 'shorturl.at', 'tiny.cc', 'lnkd.in', 'adf.ly',
    'qr.page', 'qrco.de', 'qr.codes', 'me.qr.', 'l.ead.me',
];

// Suspicious domain patterns (DGA-like domains, homograph attacks, etc.)
const SUSPICIOUS_DOMAIN_PATTERNS = [
    /\d{4,}-\d{4,}/, // Long number sequences: 1234-5678.com
    /[a-z]{20,}\./, // Very long subdomain strings
    /(paypa1|g00gle|rnaybаnk|amaz0n|m1crosoft|facbook|instgram|lloydstsb|hsb[0c])/i, // Typosquatting
    /(secure-verify|account-update|login-confirm|verify-account|update-info|bank-alert|confirm-payment)/i,
];

export interface QuishingResult {
    score: number;
    level: 'low' | 'medium' | 'high' | 'critical';
    reasons: string[];
    redirectChain: string[];
    finalUrl: string;
    detectedBy: string[];
    checkedAt: string;
    fromCache?: boolean;
}

export class QuishingService {
    /**
     * Deep-scan a URL or QR payload.
     * - Follows redirect chain (up to 10 hops)
     * - Batch-checks all URLs in chain via Google Safe Browsing
     * - Optionally checks via VirusTotal
     * - Applies quishing-specific heuristics
     */
    static async analyzeUrl(rawInput: string): Promise<QuishingResult> {
        const trimmedInput = rawInput.trim();

        // Try Redis cache first
        let redisClient: ReturnType<typeof createClient> | null = null;
        try {
            const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
            redisClient = createClient({ url: redisUrl });
            await redisClient.connect();
            const cacheKey = `quishing:${trimmedInput}`;
            const cached = await redisClient.get(cacheKey);
            if (cached) {
                await redisClient.disconnect();
                return { ...JSON.parse(String(cached)), fromCache: true };
            }
        } catch {
            // Redis unavailable — continue without cache
            redisClient = null;
        }

        const result = await QuishingService._analyze(trimmedInput);

        // Cache result
        if (redisClient) {
            try {
                const cacheKey = `quishing:${trimmedInput}`;
                await redisClient.set(cacheKey, JSON.stringify(result), { EX: CACHE_TTL_SECONDS });
                await redisClient.disconnect();
            } catch {
                // Non-fatal
            }
        }

        return result;
    }

    private static async _analyze(rawInput: string): Promise<QuishingResult> {
        const reasons: string[] = [];
        const detectedBy: string[] = [];
        let score = 0;

        // 1. Parse input — classify as URL or non-URL QR payload
        const uri = QuishingService._tryParseUrl(rawInput);

        if (!uri) {
            // Non-URL QR payload (vCard, WiFi, plain text, etc.) — generally low risk
            return {
                score: 0,
                level: 'low',
                reasons: ['ℹ️ QR code contains non-URL data (text/contact/WiFi) — no link to scan'],
                redirectChain: [],
                finalUrl: rawInput,
                detectedBy: [],
                checkedAt: new Date().toISOString(),
            };
        }

        // 2. Follow redirect chain
        const chain = await QuishingService._followRedirects(uri.href);
        const finalUrl = chain[chain.length - 1] ?? uri.href;

        if (chain.length > 1) {
            detectedBy.push('redirect_analysis');
            reasons.push(`🔗 Redirect chain: ${chain.length} hop(s) detected`);
            if (chain.length > 3) {
                score += 20;
                reasons.push(`⚠️ Excessive redirects (${chain.length} hops) — common in quishing attacks`);
            }
        }

        // 3. Quishing heuristics on original URL
        const heuristicScore = QuishingService._heuristicCheck(rawInput, uri);
        score += heuristicScore.score;
        reasons.push(...heuristicScore.reasons);
        if (heuristicScore.score > 0) detectedBy.push('heuristics');

        // 4. Heuristics on final URL (if different from original)
        if (finalUrl !== uri.href) {
            const finalUri = QuishingService._tryParseUrl(finalUrl);
            if (finalUri) {
                const finalHeuristic = QuishingService._heuristicCheck(finalUrl, finalUri);
                if (finalHeuristic.score > 0) {
                    score += Math.round(finalHeuristic.score * 0.7); // Reduced weight for final URL
                    reasons.push('⚠️ Final destination URL also flagged by heuristics');
                }
            }
        }

        // 5. Google Safe Browsing — batch check all URLs in chain
        const sbResult = await QuishingService._checkSafeBrowsing(chain);
        if (sbResult.flagged) {
            score = Math.max(score, 85);
            detectedBy.push('google_safe_browsing');
            for (const threat of sbResult.threats) {
                switch (threat) {
                    case 'SOCIAL_ENGINEERING':
                        reasons.unshift('🚨 Phishing/Social Engineering site flagged by Google Safe Browsing');
                        break;
                    case 'MALWARE':
                        reasons.unshift('🚨 Malware distribution site flagged by Google Safe Browsing');
                        break;
                    default:
                        reasons.unshift(`🚨 ${threat} flagged by Google Safe Browsing`);
                }
            }
        } else if (chain.length > 0) {
            reasons.push('✅ All URLs in redirect chain passed Google Safe Browsing');
        }

        // 6. VirusTotal (non-blocking, best-effort)
        const vtKey = process.env.VIRUSTOTAL_API_KEY;
        if (vtKey) {
            try {
                const vtResult = await Promise.race([
                    QuishingService._checkVirusTotal(finalUrl, vtKey),
                    new Promise<null>((r) => setTimeout(() => r(null), 3000)), // 3s timeout
                ]);
                if (vtResult && vtResult.malicious > 0) {
                    score = Math.max(score, 80);
                    detectedBy.push('virustotal');
                    reasons.unshift(`🚨 Flagged by ${vtResult.malicious} VirusTotal engine(s)`);
                }
            } catch {
                // VirusTotal failure is non-fatal
            }
        }

        const finalScore = Math.min(score, 100);
        const level = QuishingService._getLevel(finalScore);

        if (finalScore === 0 && reasons.filter(r => !r.startsWith('✅')).length === 0) {
            reasons.push('✅ No threats detected in link analysis');
        }

        return {
            score: finalScore,
            level,
            reasons,
            redirectChain: chain,
            finalUrl,
            detectedBy,
            checkedAt: new Date().toISOString(),
        };
    }

    // ── Redirect chain follower ─────────────────────────────────────────────

    private static async _followRedirects(startUrl: string): Promise<string[]> {
        const chain: string[] = [startUrl];
        let currentUrl = startUrl;

        for (let hop = 0; hop < MAX_REDIRECT_HOPS; hop++) {
            // Validate URL for SSRF before each request
            try {
                await validateSafeUrl(currentUrl);
            } catch (err: any) {
                // Blocked or invalid URL — stop chain
                if (hop === 0) {
                    // If the first URL is dangerous, we should still return it so it can be analyzed
                    // but we won't follow it. (Wait, if we don't follow it, we shouldn't fetch it either).
                }
                break;
            }

            let response: Response;
            try {
                const controller = new AbortController();
                const timeout = setTimeout(() => controller.abort(), HOP_TIMEOUT_MS);
                response = await fetch(currentUrl, {
                    method: 'HEAD',
                    redirect: 'manual',
                    signal: controller.signal,
                    headers: {
                        'User-Agent': 'FraudShield-SafetyBot/1.0 (security scanner)',
                    },
                });
                clearTimeout(timeout);
            } catch {
                break; // Network error — stop chain
            }

            const isRedirect = response.status >= 300 && response.status < 400;
            if (!isRedirect) break;

            const location = response.headers.get('location');
            if (!location) break;

            // Resolve relative redirects
            let nextUrl: string;
            try {
                nextUrl = new URL(location, currentUrl).href;
            } catch {
                break;
            }

            if (chain.includes(nextUrl)) break; // Redirect loop detection

            chain.push(nextUrl);
            currentUrl = nextUrl;
        }

        return chain;
    }

    // ── Heuristic checks ────────────────────────────────────────────────────

    private static _heuristicCheck(urlStr: string, uri: URL): { score: number; reasons: string[] } {
        const reasons: string[] = [];
        let score = 0;
        const lower = urlStr.toLowerCase();
        const hostname = uri.hostname.toLowerCase();

        // Shortener in QR = major red flag (quishing)
        if (QR_SHORTENERS.some((s) => hostname.includes(s))) {
            score += 40;
            reasons.push('⚠️ URL shortener in QR code — commonly used in quishing attacks');
        }

        // HTTP (not HTTPS)
        if (uri.protocol === 'http:') {
            score += 25;
            reasons.push('⚠️ Insecure connection (HTTP) — phishing sites often skip HTTPS');
        }

        // Suspicious domain patterns
        for (const pattern of SUSPICIOUS_DOMAIN_PATTERNS) {
            if (pattern.test(hostname)) {
                score += 35;
                reasons.push('⚠️ Domain name matches known phishing/typosquatting pattern');
                break; // Count once
            }
        }

        // IP address as hostname (rare in legitimate QR codes)
        if (/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(hostname)) {
            score += 40;
            reasons.push('⚠️ QR code points to an IP address (not a domain name)');
        }

        // Excessive subdomains (brand.real-bank.com.evil.net)
        const subdomainCount = hostname.split('.').length - 2;
        if (subdomainCount > 3) {
            score += 20;
            reasons.push('⚠️ Unusually deep subdomain structure (common phishing trick)');
        }

        // @ in URL (confuses users about the actual domain)
        if (urlStr.includes('@')) {
            score += 35;
            reasons.push('⚠️ URL contains "@" — used to disguise the real destination');
        }

        // Data URIs / javascript: scheme
        if (uri.protocol === 'data:' || uri.protocol === 'javascript:') {
            score += 100;
            reasons.push('🚨 Dangerous embedded code detected in QR link');
        }

        // Base64 or hex encoded payload in URL path (obfuscation)
        if (/[A-Za-z0-9+/]{50,}={0,2}/.test(uri.pathname)) {
            score += 20;
            reasons.push('⚠️ URL path contains encoded/obfuscated data');
        }

        // Tunneling services (ngrok, etc.)
        if (/(ngrok\.io|serveo\.net|localtunnel\.me|pagekite\.me)/.test(hostname)) {
            score += 60;
            reasons.push('🚨 Tunneling service detected — often used for phishing');
        }

        return { score, reasons };
    }

    // ── Google Safe Browsing ────────────────────────────────────────────────

    private static async _checkSafeBrowsing(urls: string[]): Promise<{ flagged: boolean; threats: string[] }> {
        const apiKey = process.env.GOOGLE_SAFE_BROWSING_API_KEY;
        if (!apiKey || urls.length === 0) return { flagged: false, threats: [] };

        try {
            const body = {
                client: { clientId: 'fraudshield', clientVersion: '1.0.0' },
                threatInfo: {
                    threatTypes: ['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE', 'POTENTIALLY_HARMFUL_APPLICATION'],
                    platformTypes: ['ANY_PLATFORM'],
                    threatEntryTypes: ['URL'],
                    threatEntries: urls.map((url) => ({ url })),
                },
            };

            const response = await fetch(`${SAFE_BROWSING_URL}?key=${apiKey}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body),
            });

            if (!response.ok) return { flagged: false, threats: [] };

            const data = await response.json() as { matches?: Array<{ threatType: string }> };
            const threats = (data.matches ?? []).map((m) => m.threatType);
            return { flagged: threats.length > 0, threats };
        } catch {
            return { flagged: false, threats: [] };
        }
    }

    // ── VirusTotal ──────────────────────────────────────────────────────────

    private static async _checkVirusTotal(url: string, apiKey: string): Promise<{ malicious: number } | null> {
        try {
            const encoded = Buffer.from(String(url)).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
            const response = await fetch(`${VIRUSTOTAL_URL}/${encoded}`, {
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

    // ── Helpers ─────────────────────────────────────────────────────────────

    private static _tryParseUrl(input: string): URL | null {
        // Direct parse
        try { return new URL(input); } catch { }
        // Try with https:// prefix
        try { return new URL(`https://${input}`); } catch { }
        return null;
    }

    private static _getLevel(score: number): 'low' | 'medium' | 'high' | 'critical' {
        if (score >= 80) return 'critical';
        if (score >= 55) return 'high';
        if (score >= 30) return 'medium';
        return 'low';
    }
}
