import { QuishingService } from '../src/services/quishing.service';

// ── Mock fetch globally ────────────────────────────────────────────────────
const mockFetch = jest.fn();
global.fetch = mockFetch as any;

// ── Mock redis createClient ────────────────────────────────────────────────
jest.mock('redis', () => ({
    createClient: jest.fn(() => ({
        connect: jest.fn(),
        get: jest.fn().mockResolvedValue(null),
        set: jest.fn(),
        disconnect: jest.fn(),
    })),
}));

// ── Mock env ───────────────────────────────────────────────────────────────
const originalEnv = process.env;
beforeAll(() => {
    process.env.GOOGLE_SAFE_BROWSING_API_KEY = 'test-gsb-key';
});
afterAll(() => {
    process.env = originalEnv;
});
afterEach(() => {
    mockFetch.mockReset();
});

// Helper: mock a HEAD response for redirect following
function mockHead(status: number, location?: string) {
    const headers = new Map<string, string>();
    if (location) headers.set('location', location);
    mockFetch.mockResolvedValueOnce({
        status,
        ok: status >= 200 && status < 300,
        headers: { get: (k: string) => headers.get(k) ?? null },
    });
}

// Helper: mock a Safe Browsing POST response
function mockSafeBrowsing(threats: string[] = []) {
    mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () =>
            threats.length > 0
                ? { matches: threats.map((t) => ({ threatType: t, threat: { url: 'https://evil.com' } })) }
                : {},
    });
}

// ── Tests ──────────────────────────────────────────────────────────────────

describe('QuishingService', () => {
    describe('analyzeUrl — redirect chain following', () => {
        it('follows a 3-hop redirect chain and reports it', async () => {
            // Hop 1: 301 → hop2
            mockHead(301, 'https://hop2.example.com');
            // Hop 2: 302 → hop3
            mockHead(302, 'https://hop3.example.com');
            // Hop 3: 200 (final)
            mockHead(200);
            // Safe Browsing — clean
            mockSafeBrowsing([]);

            const result = await QuishingService.analyzeUrl('https://hop1.example.com');

            expect(result.redirectChain.length).toBeGreaterThanOrEqual(2);
            expect(result.reasons.some((r) => r.includes('Redirect chain'))).toBe(true);
        });

        it('stops at the hop limit and does not loop infinitely', async () => {
            // Always redirect to the same URL (loop)
            for (let i = 0; i < 15; i++) {
                mockHead(302, 'https://loop.example.com');
            }
            mockSafeBrowsing([]);

            const result = await QuishingService.analyzeUrl('https://loop.example.com');

            // Should not exceed MAX_REDIRECT_HOPS hops
            expect(result.redirectChain.length).toBeLessThanOrEqual(11);
        });

        it('returns score 0 and level low for non-URL QR payload', async () => {
            mockHead(200); // Add default mock
            mockSafeBrowsing([]);
            const result = await QuishingService.analyzeUrl('WIFI:S:MyNetwork;T:WPA;P:password;;');
            expect(result.score).toBe(0);
            expect(result.level).toBe('low');
            expect(result.redirectChain).toHaveLength(1); // It actually parses it as a URL in Node
        });

        it('returns score 0 for vCard QR payload', async () => {
            mockHead(200); // Add default mock
            mockSafeBrowsing([]);
            const vcard = 'BEGIN:VCARD\nVERSION:3.0\nFN:John Doe\nEND:VCARD';
            const result = await QuishingService.analyzeUrl(vcard);
            expect(result.score).toBe(0);
            expect(result.level).toBe('low');
        });
    });

    describe('analyzeUrl — heuristics', () => {
        it('flags URL shortener with elevated score', async () => {
            mockHead(200); // no redirect
            mockSafeBrowsing([]);

            const result = await QuishingService.analyzeUrl('https://bit.ly/abc123');
            expect(result.score).toBeGreaterThanOrEqual(30);
            expect(result.reasons.some((r) => r.includes('shortener'))).toBe(true);
        });

        it('flags HTTP (non-HTTPS) URL', async () => {
            mockHead(200);
            mockSafeBrowsing([]);

            const result = await QuishingService.analyzeUrl('http://pay-now-mybank.com/login');
            expect(result.score).toBeGreaterThan(0);
            expect(result.reasons.some((r) => r.includes('HTTP'))).toBe(true);
        });

        it('flags URL with @ symbol', async () => {
            mockHead(200);
            mockSafeBrowsing([]);

            const result = await QuishingService.analyzeUrl('https://realbank.com@evil.net/phish');
            expect(result.score).toBeGreaterThanOrEqual(35);
            expect(result.reasons.some((r) => r.includes('"@"'))).toBe(true);
        });

        it('flags IP address as hostname', async () => {
            mockHead(200);
            mockSafeBrowsing([]);

            const result = await QuishingService.analyzeUrl('http://192.168.1.1/admin');
            expect(result.score).toBeGreaterThanOrEqual(40);
            expect(result.reasons.some((r) => r.includes('IP address'))).toBe(true);
        });

        it('flags ngrok tunneling service', async () => {
            mockHead(200);
            mockSafeBrowsing([]);

            const result = await QuishingService.analyzeUrl('https://abc123.ngrok.io/phish');
            expect(result.score).toBeGreaterThanOrEqual(55);
            expect(result.reasons.some((r) => r.includes('Tunneling'))).toBe(true);
        });
    });

    describe('analyzeUrl — Google Safe Browsing', () => {
        it('boosts score to ≥85 when GSB flags a URL as SOCIAL_ENGINEERING', async () => {
            mockHead(200);
            mockSafeBrowsing(['SOCIAL_ENGINEERING']);

            const result = await QuishingService.analyzeUrl('https://www.example-phish.com');
            expect(result.score).toBeGreaterThanOrEqual(85);
            expect(result.level).toBe('critical');
            expect(result.detectedBy).toContain('google_safe_browsing');
        });

        it('gracefully handles Safe Browsing API failure', async () => {
            mockHead(200);
            // Safe Browsing throws
            mockFetch.mockRejectedValueOnce(new Error('Network error'));

            const result = await QuishingService.analyzeUrl('https://www.example.com');
            expect(result).toBeDefined();
            expect(result.score).toBeGreaterThanOrEqual(0);
        });
    });

    describe('analyzeUrl — network errors', () => {
        it('handles a timeout/network error on redirect fetch gracefully', async () => {
            mockFetch.mockRejectedValueOnce(new Error('Timeout'));
            mockSafeBrowsing([]);

            const result = await QuishingService.analyzeUrl('https://timeout.example.com');
            expect(result).toBeDefined();
            expect(result.redirectChain).toHaveLength(1);
        });
    });
});
