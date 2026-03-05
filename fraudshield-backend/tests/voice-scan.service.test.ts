/**
 * Unit tests for VoiceScanService — Phase A
 *
 * Tests run with mocked Whisper API so no OpenAI API key is required.
 * Run: npx jest tests/voice-scan.service.test.ts
 */

import { VoiceScanService } from '../src/services/voice-scan.service';

// ── Mock the fetch global (Whisper API) ────────────────────────────────────────

const mockFetch = jest.fn();
global.fetch = mockFetch as any;

// ── Mock Redis to avoid requiring a live Redis connection ─────────────────────

jest.mock('redis', () => ({
    createClient: () => ({
        connect: jest.fn().mockResolvedValue(undefined),
        get: jest.fn().mockResolvedValue(null), // default: cache miss
        set: jest.fn().mockResolvedValue('OK'),
        disconnect: jest.fn().mockResolvedValue(undefined),
    }),
}));

// ── Whisper API mock response factory ─────────────────────────────────────────

function makeWhisperResponse(transcript: string, segments?: any[]) {
    return {
        ok: true,
        json: jest.fn().mockResolvedValue({
            text: transcript,
            language: 'en',
            duration: 45.0,
            segments: segments ?? [
                { id: 0, start: 0.0, end: 5.0, text: transcript.substring(0, 60) },
            ],
        }),
        text: jest.fn().mockResolvedValue(''),
    };
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const SCAM_CALL_EN =
    'Hello, this is Bank Negara Malaysia. Your account has been compromised. ' +
    'Please provide your OTP and bank account number immediately to verify your identity. ' +
    'Failure to comply within 24 hours will result in account suspension.';

const SAFE_CALL =
    'Hi, this is Sarah from the HR department. I just wanted to confirm that your leave ' +
    'request has been approved. Have a great weekend!';

const BNM_IMPERSONATION =
    'This is Bank Negara Malaysia calling. ' +
    'We have detected suspicious transactions on your account. ' +
    'Please share your credit card number to reverse the charges.';

const SMALL_BUFFER = Buffer.from('fake-audio-data');

// ── Tests ─────────────────────────────────────────────────────────────────────

beforeEach(() => {
    jest.clearAllMocks();
    process.env.OPENAI_API_KEY = 'test-openai-key-xxx';
});

describe('VoiceScanService.validateFile()', () => {
    it('rejects an empty buffer', () => {
        const error = VoiceScanService.validateFile(Buffer.alloc(0), 'test.wav', 'audio/wav');
        expect(error).toBe('No audio data received.');
    });

    it('rejects a file exceeding 25 MB', () => {
        const bigBuffer = Buffer.alloc(26 * 1024 * 1024); // 26 MB
        const error = VoiceScanService.validateFile(bigBuffer, 'big.wav', 'audio/wav');
        expect(error).toContain('25 MB limit');
    });

    it('rejects an unsupported format (txt file)', () => {
        const error = VoiceScanService.validateFile(SMALL_BUFFER, 'file.txt', 'text/plain');
        expect(error).toContain('Unsupported audio format');
    });

    it('accepts a valid .wav file by extension', () => {
        const error = VoiceScanService.validateFile(SMALL_BUFFER, 'recording.wav', 'audio/wav');
        expect(error).toBeNull();
    });

    it('accepts a valid .m4a file by MIME type', () => {
        const error = VoiceScanService.validateFile(SMALL_BUFFER, 'voice.m4a', 'audio/x-m4a');
        expect(error).toBeNull();
    });

    it('accepts a .webm file (from browser MediaRecorder)', () => {
        const error = VoiceScanService.validateFile(SMALL_BUFFER, 'recording.webm', 'video/webm');
        expect(error).toBeNull();
    });
});

describe('VoiceScanService.analyze() — Content (NLP) layer', () => {
    it('gives a high risk score for a Bank Negara impersonation scam call', async () => {
        mockFetch.mockResolvedValueOnce(makeWhisperResponse(SCAM_CALL_EN));

        const result = await VoiceScanService.analyze(SMALL_BUFFER, 'call.m4a', 'audio/x-m4a');

        expect(result.riskScore).toBeGreaterThanOrEqual(55);
        expect(['high', 'critical']).toContain(result.level);
        expect(result.contentAnalysis.matchedPatterns.length).toBeGreaterThan(0);
        expect(result.transcript).toBe(SCAM_CALL_EN);
    });

    it('gives a low risk score for a normal HR call', async () => {
        mockFetch.mockResolvedValueOnce(makeWhisperResponse(SAFE_CALL));

        const result = await VoiceScanService.analyze(SMALL_BUFFER, 'hr.m4a', 'audio/x-m4a');

        expect(result.riskScore).toBeLessThanOrEqual(30);
        expect(['low', 'medium']).toContain(result.level);
    });

    it('detects sensitive data request patterns (credit card request)', async () => {
        // Use a longer segment so the opener regex matches in the early transcript
        const segments = [{ id: 0, start: 0.0, end: 10.0, text: BNM_IMPERSONATION }];
        const response = {
            ok: true,
            json: jest.fn().mockResolvedValue({
                text: BNM_IMPERSONATION,
                language: 'en',
                duration: 30.0,
                segments,
            }),
            text: jest.fn().mockResolvedValue(''),
        };
        mockFetch.mockResolvedValueOnce(response);

        const result = await VoiceScanService.analyze(SMALL_BUFFER, 'bnm.m4a', 'audio/x-m4a');

        // Should be flagged at least by NLP (impersonation + credential harvest)
        expect(result.riskScore).toBeGreaterThanOrEqual(30);
        expect(result.contentAnalysis.score).toBeGreaterThanOrEqual(30);
        // Authority opener + credit card request should fire voice heuristics
        expect(result.voiceAnalysis.flags.length).toBeGreaterThan(0);
    });
});

describe('VoiceScanService.analyze() — Voice heuristics layer', () => {
    it('flags authority impersonation in first 30 seconds', async () => {
        const transcript = 'This is Bank Negara Malaysia. Your account is frozen. Provide your OTP immediately.';
        // Provide transcript in a segment within 30s so the early-transcript check fires
        const segments = [{ id: 0, start: 0.0, end: 8.0, text: transcript }];
        const response = {
            ok: true,
            json: jest.fn().mockResolvedValue({
                text: transcript,
                language: 'en',
                duration: 30.0,
                segments,
            }),
            text: jest.fn().mockResolvedValue(''),
        };
        mockFetch.mockResolvedValueOnce(response);

        const result = await VoiceScanService.analyze(SMALL_BUFFER, 'call.wav', 'audio/wav');

        // Voice score should be elevated by authority opener OR sensitive request
        expect(result.voiceAnalysis.score).toBeGreaterThan(0);
        // Combined risk should be markedly higher than a clean call
        expect(result.riskScore).toBeGreaterThanOrEqual(20);
    });

    it('detects unnaturally low silence ratio on long calls', async () => {
        const transcript = 'Robocall continuous speech without pause.';
        // Total speech == entire duration (no silence)
        const segments = [{ id: 0, start: 0.0, end: 20.0, text: transcript }];
        const response = {
            ok: true,
            json: jest.fn().mockResolvedValue({
                text: transcript,
                language: 'en',
                duration: 20.0, // same as speech time → silence ratio ≈ 0
                segments,
            }),
            text: jest.fn().mockResolvedValue(''),
        };
        mockFetch.mockResolvedValueOnce(response);

        const result = await VoiceScanService.analyze(SMALL_BUFFER, 'robocall.wav', 'audio/wav');

        expect(result.voiceAnalysis.silenceRatio).toBeLessThan(0.05);
        expect(result.voiceAnalysis.flags).toEqual(
            expect.arrayContaining([expect.stringContaining('silence ratio')]),
        );
    });

    it('flags repetitive phrases (scam hook repetition)', async () => {
        const repetitiveScript =
            'Your account is frozen. Please verify. Your account is frozen. Please verify. ' +
            'Your account is frozen. Please verify. Action is required immediately.';
        mockFetch.mockResolvedValueOnce(makeWhisperResponse(repetitiveScript));

        const result = await VoiceScanService.analyze(SMALL_BUFFER, 'repeat.wav', 'audio/wav');

        expect(result.voiceAnalysis.flags).toEqual(
            expect.arrayContaining([expect.stringContaining('Highly repetitive phrasing')]),
        );
    });

    it('flags robotic pacing based on segment duration variance', async () => {
        const transcript = 'This is a test of the robotic pacing detection system.';
        // 10 identical segments (perfectly rhythmic/robotic)
        const segments = Array.from({ length: 10 }, (_, i) => ({
            id: i,
            start: i * 2.0,
            end: i * 2.0 + 1.5, // each is exactly 1.5s
            text: 'text piece',
        }));

        const response = {
            ok: true,
            json: jest.fn().mockResolvedValue({
                text: transcript,
                language: 'en',
                duration: 20.0,
                segments,
            }),
            text: jest.fn().mockResolvedValue(''),
        };
        mockFetch.mockResolvedValueOnce(response);

        const result = await VoiceScanService.analyze(SMALL_BUFFER, 'robot.wav', 'audio/wav');

        expect(result.voiceAnalysis.flags).toEqual(
            expect.arrayContaining([expect.stringContaining('Robotic pacing detected')]),
        );
    });
});

describe('VoiceScanService.analyze() — Response structure', () => {
    it('returns all required fields', async () => {
        mockFetch.mockResolvedValueOnce(makeWhisperResponse(SAFE_CALL));

        const result = await VoiceScanService.analyze(SMALL_BUFFER, 'call.m4a', 'audio/x-m4a');

        expect(result).toMatchObject({
            riskScore: expect.any(Number),
            level: expect.stringMatching(/^(low|medium|high|critical)$/),
            transcript: expect.any(String),
            language: expect.any(String),
            duration: expect.any(Number),
            sha256: expect.any(String),
            disclaimer: expect.any(String),
            contentAnalysis: {
                score: expect.any(Number),
                scamType: expect.any(String),
                matchedPatterns: expect.any(Array),
            },
            voiceAnalysis: {
                score: expect.any(Number),
                flags: expect.any(Array),
            },
        });
    });

    it('clamps riskScore between 0 and 100', async () => {
        mockFetch.mockResolvedValueOnce(makeWhisperResponse(SCAM_CALL_EN));

        const result = await VoiceScanService.analyze(SMALL_BUFFER, 'call.m4a', 'audio/x-m4a');

        expect(result.riskScore).toBeGreaterThanOrEqual(0);
        expect(result.riskScore).toBeLessThanOrEqual(100);
    });
});

describe('VoiceScanService.analyze() — Error handling', () => {
    it('throws if OPENAI_API_KEY is not set', async () => {
        delete process.env.OPENAI_API_KEY;

        await expect(
            VoiceScanService.analyze(SMALL_BUFFER, 'call.m4a', 'audio/mp4'),
        ).rejects.toThrow('OPENAI_API_KEY is not configured');
    });

    it('throws if Whisper API returns an error status', async () => {
        mockFetch.mockResolvedValueOnce({
            ok: false,
            status: 429,
            text: jest.fn().mockResolvedValue('Rate limit exceeded'),
        });

        await expect(
            VoiceScanService.analyze(SMALL_BUFFER, 'call.m4a', 'audio/mp4'),
        ).rejects.toThrow('Whisper API error 429');
    });
});
