export interface HeuristicResult {
    score: number;
    reasons: string[];
}

export class UrlHeuristicService {
    private static readonly DANGEROUS_SCHEMES = ['javascript', 'vbs', 'file', 'data'];
    private static readonly STANDARD_SCHEMES = ['http', 'https', 'mailto', 'tel', 'sms', 'geo'];
    private static readonly SHORTENERS = [
        'bit.ly',
        'tinyurl.com',
        'goo.gl',
        't.co',
        'is.gd',
        'buff.ly',
        'ow.ly',
    ];

    private static readonly SUSPICIOUS_KEYWORDS = [
        'login',
        'verify',
        'bank',
        'secure',
        'update',
        'account',
        'reward',
        'free',
        'claim',
        'bonus',
        'gift',
        'winner',
        'urgent',
        'action',
        'suspend',
        'limited',
        'maybank',
        'cimb',
        'pbebank',
        'hlb',
        'rhb',
    ];

    /**
     * Performs heuristic analysis on a URL.
     */
    static analyze(url: string): HeuristicResult {
        let score = 0;
        const reasons: string[] = [];
        const lowerUrl = url.toLowerCase();

        try {
            const urlObj = new URL(url);

            // 1. Dangerous schemes
            if (this.DANGEROUS_SCHEMES.includes(urlObj.protocol.replace(':', ''))) {
                return {
                    score: 100,
                    reasons: [`Dangerous script or file execution detected (${urlObj.protocol})`],
                };
            }

            // 2. Non-standard schemes
            const scheme = urlObj.protocol.replace(':', '');
            if (scheme && !this.STANDARD_SCHEMES.includes(scheme)) {
                score += 20;
                reasons.push(`Unusual link type detected (${scheme})`);
            }

            // 3. Insecure HTTP
            if (urlObj.protocol === 'http:') {
                score += 30;
                reasons.push('Insecure connection (HTTP instead of HTTPS)');
            }
        } catch (e) {
            // Not a standard URL, might still match keywords or patterns
            score += 10;
        }

        // 4. Shorteners
        if (this.SHORTENERS.some((domain) => lowerUrl.includes(domain))) {
            score += 40;
            reasons.push('URL shortener detected (often used to hide scams)');
        }

        // 5. Keywords
        let keywordCount = 0;
        for (const k of this.SUSPICIOUS_KEYWORDS) {
            if (lowerUrl.includes(k)) {
                keywordCount++;
            }
        }

        if (keywordCount > 0) {
            score += 20 + keywordCount * 10;
            reasons.push(`Contains words commonly used in phishing (${keywordCount} found)`);
        }

        // 6. Phishing Patterns
        if (lowerUrl.includes('ngrok') || lowerUrl.includes('serveo')) {
            score += 80;
            reasons.push('Tunneling service detected (often used for phishing)');
        }

        if (url.includes('@')) {
            score += 50;
            reasons.push('URL contains "@" (often used to trick users)');
        }

        return { score, reasons };
    }
}
