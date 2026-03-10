import { Request, Response, NextFunction } from 'express';
import { QuishingService } from '../services/quishing.service';
import { prisma } from '../config/database';
import { CheckType } from '@prisma/client';

export class QuishingController {
    /**
     * POST /api/v1/features/check-link
     * Body: { url: string }
     * Deep-scans a URL: follows redirects, checks Safe Browsing, applies heuristics.
     */
    static async checkLink(req: Request, res: Response, next: NextFunction) {
        try {
            const { url } = req.body;

            if (!url || typeof url !== 'string' || url.trim().length === 0) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: 'A valid "url" string is required.',
                });
            }

            if (url.length > 2048) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: 'URL exceeds maximum length of 2048 characters.',
                });
            }

            const result = await QuishingService.analyzeUrl(url.trim());

            let journalId: string | undefined;

            // Log to TransactionJournal
            const userId = (req.user as any)?.id;
            if (userId) {
                const journal = await (prisma as any).transactionJournal.create({
                    data: {
                        userId,
                        checkType: CheckType.URL,
                        target: url.trim(),
                        riskScore: result.score,
                        status: result.score >= 30 ? 'SUSPICIOUS' : 'SAFE',
                        metadata: {
                            level: result.level,
                            redirectChain: result.redirectChain,
                            finalUrl: result.finalUrl,
                            detectedBy: result.detectedBy,
                            source: 'check-link',
                        },
                    },
                });
                journalId = journal.id;
            }

            return res.json({
                ...result,
                journalId,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/v1/features/check-qr
     * Body: { payload: string }
     * Same deep-scan but semantically for QR payloads.
     * Handles non-URL QR content (vCard, WiFi, plain text) gracefully.
     */
    static async checkQr(req: Request, res: Response, next: NextFunction) {
        try {
            const { payload } = req.body;

            if (!payload || typeof payload !== 'string' || payload.trim().length === 0) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: 'A valid "payload" string is required.',
                });
            }

            if (payload.length > 4096) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: 'QR payload exceeds maximum length of 4096 characters.',
                });
            }

            const result = await QuishingService.analyzeUrl(payload.trim());

            let journalId: string | undefined;

            // Log to TransactionJournal
            const userId = (req.user as any)?.id;
            if (userId) {
                const journal = await (prisma as any).transactionJournal.create({
                    data: {
                        userId,
                        checkType: CheckType.URL,
                        target: payload.trim().substring(0, 500), // Cap for DB storage
                        riskScore: result.score,
                        status: result.score >= 30 ? 'SUSPICIOUS' : 'SAFE',
                        metadata: {
                            level: result.level,
                            redirectChain: result.redirectChain,
                            finalUrl: result.finalUrl,
                            detectedBy: result.detectedBy,
                            source: 'check-qr',
                        },
                    },
                });
                journalId = journal.id;
            }

            return res.json({
                ...result,
                journalId,
            });
        } catch (error) {
            next(error);
        }
    }
}
