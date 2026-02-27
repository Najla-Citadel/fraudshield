import crypto from 'crypto';
import { createClient } from 'redis';
import { NlpMessageService } from './nlp-message.service';

const CACHE_TTL_SECONDS = 60 * 60; // 1 hour — audio hashes are stable
const WHISPER_API_URL = 'https://api.openai.com/v1/audio/transcriptions';
const MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024; // 25 MB (Whisper API limit)
const WHISPER_TIMEOUT_MS = 60_000; // 60 seconds

/** Supported audio MIME types accepted by Whisper API */
const SUPPORTED_MIME_TYPES = new Set([
    'audio/mpeg',        // .mp3
    'audio/mp4',         // .m4a / .mp4
    'audio/wav',         // .wav
    'audio/wave',        // .wav (alternative)
    'audio/x-wav',       // .wav (alternative)
    'audio/ogg',         // .ogg
    'audio/webm',        // .webm
    'audio/x-m4a',       // .m4a (alternative)
    'audio/flac',        // .flac
    'video/webm',        // .webm (from browser MediaRecorder)
    'video/mp4',         // .mp4
]);

const SUPPORTED_EXTENSIONS = new Set(['.mp3', '.mp4', '.m4a', '.wav', '.ogg', '.webm', '.flac']);

// ── Voice-pattern heuristics ─────────────────────────────────────────────────

/** Malaysian authority names that scammers impersonate via phone */
const VOICE_SCAM_OPENERS = [
    /\b(bank negara|bnm)\b/i,
    /\b(polis diraja malaysia|pdrm|balai polis)\b/i,
    /\b(sprm|suruhanjaya)\b/i,
    /\b(lhdn|hasil|inland revenue)\b/i,
    /\b(lembaga hasil dalam negeri)\b/i,
    /\b(kementerian|jabatan)\b/i,
    /\b(maybank|cimb|public bank|hongleong|rhb|ambank)\b.*\b(fraud|security|scam)\b/i,
];

/** Phrases that signal the caller is asking for sensitive info */
const SENSITIVE_REQUEST_PATTERNS = [
    /\b(otp|one.?time.?password|pin number|nombor pin)\b/i,
    /\b(ic number|nombor ic|kad pengenalan|mykad)\b/i,
    /\b(bank account number|nombor akaun|account details)\b/i,
    /\b(credit card|debit card|card number)\b/i,
    /\b(password|kata laluan)\b/i,
    /\b(transfer|hantar|send).{0,30}(money|wang|rm|fund)/i,
];

// ── Result Types ─────────────────────────────────────────────────────────────

export interface WhisperSegment {
    id: number;
    start: number;
    end: number;
    text: string;
}

export interface VoiceAnalysisResult {
    riskScore: number;
    level: 'low' | 'medium' | 'high' | 'critical';
    transcript: string;
    language: string;
    duration: number;
    contentAnalysis: {
        score: number;
        scamType: string;
        matchedPatterns: string[];
        highlightedPhrases: string[];
    };
    voiceAnalysis: {
        score: number;
        silenceRatio: number | null;
        flags: string[];
    };
    disclaimer: string;
    sha256: string;
    fromCache?: boolean;
    checkedAt: string;
}

// ── Service ───────────────────────────────────────────────────────────────────

export class VoiceScanService {

    /**
     * Main entry point.
     * 1. Hash audio buffer for caching
     * 2. Transcribe via OpenAI Whisper API
     * 3. Run transcript through NlpMessageService
     * 4. Apply voice-pattern heuristics
     * 5. Combine into a weighted risk score
     */
    static async analyze(
        buffer: Buffer,
        originalFilename: string,
        mimeType: string,
    ): Promise<VoiceAnalysisResult> {

        const sha256 = crypto.createHash('sha256').update(buffer).digest('hex');

        // Check Redis cache first — same audio hash → same result
        const cached = await VoiceScanService._checkCache(sha256);
        if (cached) return cached;

        // Transcribe
        const transcription = await VoiceScanService._transcribe(buffer, originalFilename, mimeType);

        const transcript = transcription.text?.trim() ?? '';
        const language = transcription.language ?? 'unknown';
        const duration = transcription.duration ?? 0;
        const segments: WhisperSegment[] = transcription.segments ?? [];

        // ── Content analysis via existing NLP engine ──
        let contentScore = 0;
        let scamType = 'unknown';
        let matchedPatterns: string[] = [];
        let highlightedPhrases: string[] = [];

        if (transcript.length > 0) {
            const nlpResult = NlpMessageService.analyze(transcript);
            contentScore = nlpResult.score;
            scamType = nlpResult.scamType ?? 'unknown';
            matchedPatterns = nlpResult.matchedPatterns ?? [];
            highlightedPhrases = nlpResult.highlightedPhrases ?? [];
        }

        // ── Voice-pattern heuristics ──
        const voiceFlags: string[] = [];
        let voiceScore = 0;

        // 1. Authority-opener detection (first 30 seconds of transcript)
        const earlyTranscript = segments
            .filter(s => s.start < 30)
            .map(s => s.text)
            .join(' ') || transcript.substring(0, 500);

        for (const pattern of VOICE_SCAM_OPENERS) {
            if (pattern.test(earlyTranscript)) {
                voiceFlags.push('Authority impersonation detected in call opening');
                voiceScore += 30;
                break;
            }
        }

        // 2. Sensitive data request
        let sensitiveCount = 0;
        for (const pattern of SENSITIVE_REQUEST_PATTERNS) {
            if (pattern.test(transcript)) sensitiveCount++;
        }
        if (sensitiveCount >= 2) {
            voiceFlags.push(`Caller requested ${sensitiveCount} types of sensitive information`);
            voiceScore += Math.min(sensitiveCount * 15, 40);
        } else if (sensitiveCount === 1) {
            voiceFlags.push('Caller requested sensitive information');
            voiceScore += 15;
        }

        // 3. Silence ratio analysis (from Whisper segments)
        let silenceRatio: number | null = null;
        if (segments.length > 0 && duration > 0) {
            const totalSpeechTime = segments.reduce((sum, s) => sum + (s.end - s.start), 0);
            silenceRatio = Math.max(0, 1 - totalSpeechTime / duration);
            // Very low silence = robocall / TTS (unnaturally continuous speech)
            if (silenceRatio < 0.05 && duration > 15) {
                voiceFlags.push('Unnaturally low silence ratio — possible automated/TTS voice');
                voiceScore += 15;
            }
        }

        // 4. Phase B: Script Repetition Detection (look for n-grams)
        const repetitionResult = VoiceScanService._detectRepetition(transcript);
        if (repetitionResult.isRepetitive) {
            voiceFlags.push(`Highly repetitive phrasing detected ("${repetitionResult.phrase}")`);
            voiceScore += 25;
        }

        // 5. Phase B: Speech Pacing Analysis (Standard Deviation of segment durations)
        const pacingResult = VoiceScanService._analyzePacing(segments);
        if (pacingResult.isRobotic && duration > 10) {
            voiceFlags.push('Robotic pacing detected — rhythmic patterns consistent with TTS');
            voiceScore += 20;
        }

        voiceScore = Math.min(voiceScore, 100);

        // ── Weighted combined score (NLP: 50%, Voice heuristics: 50% for Phase B) ──
        const rawCombined = (contentScore * 0.50) + (voiceScore * 0.50);
        const riskScore = Math.min(Math.round(rawCombined), 100);

        const result: VoiceAnalysisResult = {
            riskScore,
            level: VoiceScanService._getLevel(riskScore),
            transcript: transcript.substring(0, 5000), // Store first 5000 chars
            language,
            duration,
            contentAnalysis: {
                score: contentScore,
                scamType,
                matchedPatterns,
                highlightedPhrases,
            },
            voiceAnalysis: {
                score: voiceScore,
                silenceRatio,
                flags: voiceFlags,
            },
            disclaimer:
                'This analysis is AI-assisted and advisory only. Results are not a guarantee. ' +
                'If you suspect fraud, contact your bank or PDRM immediately at 03-2610 1559.',
            sha256,
            checkedAt: new Date().toISOString(),
        };

        await VoiceScanService._saveToCache(sha256, result);
        return result;
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    /**
     * Phase B: Detects recurring 3-5 word phrases in the transcript.
     * Scam scripts often repeat hooks like "your account is frozen" or "action is required".
     */
    private static _detectRepetition(text: string): { isRepetitive: boolean; phrase: string } {
        if (!text || text.split(/\s+/).length < 10) return { isRepetitive: false, phrase: '' };

        const words = text.toLowerCase().replace(/[.,!?;:]/g, '').split(/\s+/).filter(w => w.length > 2);
        const nLimit = 4; // Check 4-word sequences
        const counts = new Map<string, number>();

        for (let i = 0; i <= words.length - nLimit; i++) {
            const nGram = words.slice(i, i + nLimit).join(' ');
            counts.set(nGram, (counts.get(nGram) || 0) + 1);
        }

        let maxCount = 0;
        let maxPhrase = '';
        for (const [phrase, count] of counts.entries()) {
            if (count > maxCount) {
                maxCount = count;
                maxPhrase = phrase;
            }
        }

        // If a 4-word phrase repeats 3+ times in a short transcript, it's highly suspicious
        return { isRepetitive: maxCount >= 3, phrase: maxPhrase };
    }

    /**
     * Phase B: Analyzes the standard deviation of speech pacing.
     * Human speech has high variance; robotic TTS is perfectly rhythmic.
     */
    private static _analyzePacing(segments: WhisperSegment[]): { isRobotic: boolean; stdev: number } {
        if (segments.length < 5) return { isRobotic: false, stdev: 0 };

        const durations = segments.map(s => s.end - s.start);
        const mean = durations.reduce((a, b) => a + b, 0) / durations.length;
        const variance = durations.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / durations.length;
        const stdev = Math.sqrt(variance);

        // Very low standard deviation (< 0.35s) in segment length hints at automated playback
        return { isRobotic: stdev < 0.35, stdev };
    }

    /**
     * Send audio buffer to OpenAI Whisper API.
     * Returns raw Whisper verbose_json response.
     */
    private static async _transcribe(
        buffer: Buffer,
        filename: string,
        mimeType: string,
    ): Promise<any> {
        const apiKey = process.env.OPENAI_API_KEY;
        if (!apiKey) {
            throw new Error(
                'OPENAI_API_KEY is not configured. ' +
                'Add it to your .env file to enable voice transcription.',
            );
        }

        // Build multipart/form-data payload using native FormData + Blob
        // Convert Buffer → Uint8Array so it's accepted as a valid BlobPart in all TS targets
        const formData = new FormData();
        const blob = new Blob([new Uint8Array(buffer)], { type: mimeType });
        formData.append('file', blob, filename);
        formData.append('model', 'whisper-1');
        formData.append('response_format', 'verbose_json'); // Gives us segments + timestamps
        formData.append('timestamp_granularities[]', 'segment');

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), WHISPER_TIMEOUT_MS);

        try {
            const response = await fetch(WHISPER_API_URL, {
                method: 'POST',
                headers: { Authorization: `Bearer ${apiKey}` },
                body: formData,
                signal: controller.signal,
            });

            if (!response.ok) {
                const errorBody = await response.text().catch(() => '');
                throw new Error(
                    `Whisper API error ${response.status}: ${errorBody}`,
                );
            }

            return await response.json();
        } finally {
            clearTimeout(timeoutId);
        }
    }

    /**
     * Check Redis for a cached result.
     */
    private static async _checkCache(sha256: string): Promise<VoiceAnalysisResult | null> {
        let client: ReturnType<typeof createClient> | null = null;
        try {
            client = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
            await client.connect();
            const cached = await client.get(`voice:${sha256}`);
            if (typeof cached === 'string') {
                return { ...JSON.parse(cached), fromCache: true };
            }
        } catch {
            // Cache miss or Redis unavailable — proceed normally
        } finally {
            try { await client?.disconnect(); } catch { /* ignore */ }
        }
        return null;
    }

    /**
     * Store result in Redis cache.
     */
    private static async _saveToCache(sha256: string, result: VoiceAnalysisResult): Promise<void> {
        let client: ReturnType<typeof createClient> | null = null;
        try {
            client = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
            await client.connect();
            await client.set(`voice:${sha256}`, JSON.stringify(result), { EX: CACHE_TTL_SECONDS });
        } catch {
            // Non-fatal: cache write failure
        } finally {
            try { await client?.disconnect(); } catch { /* ignore */ }
        }
    }

    /**
     * Validate the uploaded audio file before processing.
     * Returns an error message string or null if valid.
     */
    static validateFile(
        buffer: Buffer,
        originalFilename: string,
        mimeType: string,
    ): string | null {
        if (!buffer || buffer.length === 0) return 'No audio data received.';

        if (buffer.length > MAX_FILE_SIZE_BYTES) {
            return `Audio file exceeds the 25 MB limit (received ${(buffer.length / 1024 / 1024).toFixed(1)} MB).`;
        }

        const ext = originalFilename.substring(originalFilename.lastIndexOf('.')).toLowerCase();

        const hasValidMime = SUPPORTED_MIME_TYPES.has(mimeType);
        const hasValidExt = SUPPORTED_EXTENSIONS.has(ext);

        if (!hasValidMime && !hasValidExt) {
            return `Unsupported audio format. Accepted formats: MP3, MP4, M4A, WAV, OGG, WebM, FLAC.`;
        }

        return null;
    }

    private static _getLevel(score: number): 'low' | 'medium' | 'high' | 'critical' {
        if (score >= 80) return 'critical';
        if (score >= 55) return 'high';
        if (score >= 30) return 'medium';
        return 'low';
    }
}
