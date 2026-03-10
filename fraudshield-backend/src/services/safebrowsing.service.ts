import axios from 'axios';

const SAFE_BROWSING_URL = 'https://safebrowsing.googleapis.com/v4/threatMatches:find';

export interface SafeBrowsingMatch {
    threatType: string;
    threat: {
        url: string;
    };
}

export interface SafeBrowsingResult {
    url: string;
    safe: boolean;
    threats: string[];
    threatCount: number;
}

export class SafeBrowsingService {
    /**
     * Checks a URL against Google Safe Browsing v4 Lookup API.
     */
    static async checkUrl(url: string): Promise<SafeBrowsingResult> {
        const apiKey = process.env.GOOGLE_SAFE_BROWSING_API_KEY;

        if (!apiKey) {
            console.warn('[SafeBrowsingService] GOOGLE_SAFE_BROWSING_API_KEY not configured. Skipping check.');
            return {
                url,
                safe: true,
                threats: [],
                threatCount: 0,
            };
        }

        const requestBody = {
            client: {
                clientId: 'fraudshield',
                clientVersion: '1.0.1',
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

        try {
            const response = await axios.post(`${SAFE_BROWSING_URL}?key=${apiKey}`, requestBody, {
                headers: { 'Content-Type': 'application/json' },
                timeout: 5000, // 5 second timeout
            });

            const data = response.data as { matches?: SafeBrowsingMatch[] };
            const matches = data.matches || [];
            
            return {
                url,
                safe: matches.length === 0,
                threats: matches.map((m) => m.threatType),
                threatCount: matches.length,
            };
        } catch (error: any) {
            console.error('[SafeBrowsingService] Error checking URL:', error.message);
            // Fallback to safe if service is down to prevent blocking
            return {
                url,
                safe: true,
                threats: [],
                threatCount: 0,
            };
        }
    }
}
