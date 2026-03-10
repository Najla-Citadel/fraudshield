import { Request, Response, NextFunction } from 'express';
import { RiskEvaluationService } from '../services/risk-evaluation.service';
import { prisma } from '../config/database';

export class RiskEvaluationController {
    /**
     * POST /api/v1/features/evaluate-risk
     * Body: { type: 'phone' | 'bank' | 'url' | 'doc', value: string }
     *
     * Returns a V2 risk score combining community intelligence, verification ratio,
     * reporter reputation, and recency — fully computed on the backend.
     */
    static async evaluate(req: Request, res: Response, next: NextFunction) {
        try {
            const { type, value } = req.body;

            if (!type || !value || typeof value !== 'string') {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: '"type" and "value" are required.',
                });
            }

            const validTypes = ['phone', 'bank', 'url', 'doc'];
            if (!validTypes.includes(type.toLowerCase())) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: `"type" must be one of: ${validTypes.join(', ')}.`,
                });
            }

            const result = await RiskEvaluationService.evaluate(type.toLowerCase(), value);

            let journalId: string | undefined;

            // Log the check to TransactionJournal if authenticated
            const userId = (req.user as any)?.id;
            if (userId) {
                const checkTypeMap: Record<string, string> = {
                    phone: 'PHONE',
                    bank: 'BANK',
                    url: 'URL',
                    doc: 'DOC',
                };
                try {
                    const journal = await (prisma as any).transactionJournal.create({
                        data: {
                            userId,
                            checkType: checkTypeMap[type.toLowerCase()] as any,
                            target: value,
                            riskScore: result.score,
                            status: result.score >= 30 ? 'SUSPICIOUS' : 'SAFE',
                            metadata: {
                                level: result.level,
                                factors: result.factors,
                            },
                        },
                    });
                    journalId = journal.id;
                } catch (err) {
                    console.error('Failed to log to TransactionJournal:', err);
                }
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
