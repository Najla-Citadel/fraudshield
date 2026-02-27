import { Request, Response, NextFunction } from 'express';
import { VoiceScanService } from '../services/voice-scan.service';
import { prisma } from '../config/database';
import { CheckType } from '@prisma/client';

export class VoiceScanController {
    /**
     * POST /api/v1/features/analyze-voice
     * Multipart: file = audio file (mp3, wav, m4a, ogg, webm, flac — max 25 MB)
     *
     * Premium-only: requires an active Shield Basic or Shield Family subscription.
     * Admin role bypass: Admins can always use the feature for verification.
     */
    static async analyzeVoice(req: Request, res: Response, next: NextFunction) {
        const user = req.user as { id: string; role: string };

        try {
            // ── 1. Premium gate ──────────────────────────────────────────────
            // Check for active subscription
            const activeSubscription = await prisma.userSubscription.findFirst({
                where: {
                    userId: user.id,
                    isActive: true,
                    endDate: { gt: new Date() },
                },
                include: { plan: true },
            });

            // Allow access if active subscription exists OR user is an admin
            if (!activeSubscription && user.role !== 'admin') {
                console.log(`[VoiceScan] Access denied for user ${user.id} (Role: ${user.role})`);
                return res.status(403).json({
                    success: false,
                    error: 'PremiumRequired',
                    message:
                        'Voice Scam Detection is available exclusively for premium subscribers. ' +
                        'Upgrade your plan to unlock this feature.',
                    upgradeUrl: '/subscription',
                });
            }

            // ── 2. File validation ───────────────────────────────────────────
            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    error: 'NoFileUploaded',
                    message: 'No audio file was uploaded. Please record or select an audio file.',
                });
            }

            const validationError = VoiceScanService.validateFile(
                req.file.buffer,
                req.file.originalname,
                req.file.mimetype,
            );
            if (validationError) {
                return res.status(400).json({
                    success: false,
                    error: 'InvalidFile',
                    message: validationError,
                });
            }

            // ── 3. Analyse ───────────────────────────────────────────────────
            const result = await VoiceScanService.analyze(
                req.file.buffer,
                req.file.originalname,
                req.file.mimetype,
            );

            // ── 4. Log to TransactionJournal (non-fatal) ─────────────────────
            // Raw audio is discarded after analysis. Only transcript + hash stored.
            try {
                await prisma.transactionJournal.create({
                    data: {
                        userId: user.id,
                        checkType: CheckType.VOICE,
                        target: result.sha256, // Store SHA-256 hash, NOT the audio
                        riskScore: result.riskScore,
                        status: result.riskScore >= 55 ? 'SUSPICIOUS' : 'SAFE',
                        metadata: {
                            level: result.level,
                            language: result.language,
                            duration: result.duration,
                            scamType: result.contentAnalysis.scamType,
                            matchedPatterns: result.contentAnalysis.matchedPatterns,
                            voiceFlags: result.voiceAnalysis.flags,
                            // Transcript stored for user's own reference
                            transcript: result.transcript.substring(0, 1000),
                            source: 'voice_scan',
                        },
                    },
                });
            } catch {
                // Non-fatal — analysis result still returned to user
            }

            return res.json({ success: true, data: result });
        } catch (error: any) {
            // Whisper API not configured
            if (error?.message?.includes('OPENAI_API_KEY')) {
                return res.status(503).json({
                    success: false,
                    error: 'ServiceUnavailable',
                    message: 'Voice analysis service is not yet configured. Please contact support.',
                });
            }
            next(error);
        }
    }
}
