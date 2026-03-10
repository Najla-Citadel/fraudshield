import { Request, Response, NextFunction } from 'express';
import { NlpMessageService } from '../services/nlp-message.service';
import { prisma } from '../config/database';
import { CheckType } from '@prisma/client';

const MAX_MESSAGE_LENGTH = 5000;

export class NlpMessageController {
    /**
     * POST /api/v1/features/analyze-message
     * Body: { message: string }
     * Analyzes a text message for scam patterns using rule-based NLP (EN/BM/ZH).
     */
    static async analyzeMessage(req: Request, res: Response, next: NextFunction) {
        try {
            const { message } = req.body;

            if (!message || typeof message !== 'string' || message.trim().length === 0) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: 'A non-empty "message" string is required.',
                });
            }

            if (message.length > MAX_MESSAGE_LENGTH) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: `Message exceeds maximum length of ${MAX_MESSAGE_LENGTH} characters.`,
                });
            }

            const result = NlpMessageService.analyze(message.trim());

            let journalId: string | undefined;

            // Log to TransactionJournal (using 'MSG' as checkType string)
            const userId = (req.user as any)?.id;
            if (userId) {
                const journal = await (prisma as any).transactionJournal.create({
                    data: {
                        userId,
                        checkType: CheckType.MSG,
                        target: message.trim().substring(0, 500), // Store first 500 chars
                        riskScore: result.score,
                        status: result.score >= 55 ? 'SUSPICIOUS' : 'SAFE',
                        metadata: {
                            level: result.level,
                            scamType: result.scamType,
                            language: result.language,
                            matchedPatterns: result.matchedPatterns,
                        },
                    },
                });
                journalId = journal.id;
            }

            // Obfuscate detailed patterns for non-admins to prevent evasion mapping (Audit #4)
            const isAdminUser = (req.user as any)?.role === 'ADMIN';
            const responseData = isAdminUser ? { ...result, journalId } : {
                score: result.score,
                level: result.level,
                scamType: result.scamType,
                language: result.language,
                checkedAt: result.checkedAt,
                matchedPatterns: result.matchedPatterns,
                journalId,
            };

            return res.json(responseData);
        } catch (error) {
            next(error);
        }
    }
}
