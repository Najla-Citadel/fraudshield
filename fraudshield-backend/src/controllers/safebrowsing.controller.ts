import { Request, Response, NextFunction } from 'express';

const SAFE_BROWSING_URL = 'https://safebrowsing.googleapis.com/v4/threatMatches:find';

export class SafeBrowsingController {
    /**
     * POST /features/check-url
     * Body: { url: string }
     * 
     * Checks a URL against Google Safe Browsing v4 Lookup API.
     * Returns threat info if the URL is flagged.
     */
    static async checkUrl(req: Request, res: Response, next: NextFunction) {
        try {
            const { url } = req.body;

            if (!url || typeof url !== 'string') {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: 'A valid "url" string is required in the request body.',
                });
            }

            const apiKey = process.env.GOOGLE_SAFE_BROWSING_API_KEY;

            if (!apiKey) {
                console.error('GOOGLE_SAFE_BROWSING_API_KEY is not set in environment.');
                return res.status(503).json({
                    error: 'Service Unavailable',
                    message: 'URL checking service is not configured.',
                });
            }

            // Build the Safe Browsing v4 Lookup request
            const requestBody = {
                client: {
                    clientId: 'fraudshield',
                    clientVersion: '1.0.0',
                },
                threatInfo: {
                    threatTypes: [
                        'MALWARE',
                        'SOCIAL_ENGINEERING',
                        'UNWANTED_SOFTWARE',
                        'POTENTIALLY_HARMFUL_APPLICATION',
                    ],
                    platformTypes: ['ANY_PLATFORM'],
                    threatEntryTypes: ['URL'],
                    threatEntries: [{ url }],
                },
            };

            const response = await fetch(`${SAFE_BROWSING_URL}?key=${apiKey}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(requestBody),
            });

            if (!response.ok) {
                const errorText = await response.text();
                console.error(`Safe Browsing API error (${response.status}):`, errorText);
                return res.status(502).json({
                    error: 'Bad Gateway',
                    message: 'Failed to reach the URL checking service.',
                });
            }

            const data = await response.json() as { matches?: Array<{ threatType: string; threat: { url: string } }> };

            // If matches exist, the URL is flagged as dangerous
            const matches = data.matches || [];
            const threats = matches.map((m) => m.threatType);

            res.json({
                url,
                safe: matches.length === 0,
                threats,
                threatCount: matches.length,
                checkedAt: new Date().toISOString(),
            });
        } catch (error) {
            next(error);
        }
    }
}
