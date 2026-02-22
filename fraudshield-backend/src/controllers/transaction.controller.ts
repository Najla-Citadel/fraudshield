import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';

export class TransactionController {
    /**
     * GET /api/v1/transactions
     * Fetch the authenticated user's Transaction Journal history
     */
    static async getMyTransactions(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { type, limit = '20', offset = '0' } = req.query;

            const whereClause: any = { userId };

            // Optional filter by CheckType (PHONE, URL, BANK, DOC)
            if (type && typeof type === 'string') {
                whereClause.checkType = type.toUpperCase();
            }

            const limitNum = parseInt(limit as string, 10);
            const offsetNum = parseInt(offset as string, 10);

            const [transactions, total] = await Promise.all([
                prisma.transactionJournal.findMany({
                    where: whereClause,
                    orderBy: { createdAt: 'desc' },
                    take: limitNum,
                    skip: offsetNum,
                }),
                prisma.transactionJournal.count({ where: whereClause }),
            ]);

            res.json({
                results: transactions,
                total,
                hasMore: offsetNum + limitNum < total,
                limit: limitNum,
                offset: offsetNum,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/v1/transactions/:id
     * Fetch a specific transaction's detailed metadata
     */
    static async getTransactionDetails(req: Request, res: Response, next: NextFunction) {
        try {
            const id = req.params.id as string;
            const userId = (req.user as any).id;

            const transaction = await prisma.transactionJournal.findUnique({
                where: { id },
            });

            if (!transaction) {
                return res.status(404).json({ message: 'Transaction record not found' });
            }

            if (transaction.userId !== userId) {
                return res.status(403).json({ message: 'Access denied' });
            }

            res.json(transaction);
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/v1/transactions
     * Manually log a transaction for historical tracking
     */
    static async logTransaction(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const {
                amount,
                merchant,
                target,
                paymentMethod,
                platform,
                notes
            } = req.body;

            const transaction = await prisma.transactionJournal.create({
                data: {
                    userId,
                    checkType: 'MANUAL',
                    target: target || merchant,
                    amount: amount ? parseFloat(amount) : null,
                    merchant,
                    paymentMethod,
                    platform,
                    notes,
                    riskScore: 0, // Manual logs are neutral by default
                    status: 'SAFE',
                    metadata: {
                        source: 'manual_entry',
                        loggedAt: new Date(),
                    }
                }
            });

            res.status(201).json(transaction);
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/v1/transactions/:id/report
     * Convert a transaction log into a full ScamReport
     */
    static async convertToReport(req: Request, res: Response, next: NextFunction) {
        try {
            const id = req.params.id as string;
            const userId = (req.user as any).id;
            const { description, category } = req.body;

            const tx = await prisma.transactionJournal.findUnique({
                where: { id },
            });

            if (!tx) {
                return res.status(404).json({ message: 'Transaction record not found' });
            }

            if (tx.userId !== userId) {
                return res.status(403).json({ message: 'Access denied' });
            }

            // Create the ScamReport
            const report = await prisma.scamReport.create({
                data: {
                    userId,
                    type: tx.paymentMethod || 'manual',
                    target: tx.target,
                    targetType: tx.checkType.toLowerCase() === 'manual' ? 'merchant' : tx.checkType.toLowerCase(),
                    description: description || tx.notes || 'Converted from transaction journal',
                    category: category || tx.platform || 'General',
                    status: 'pending',
                    isPublic: true,
                    evidence: {
                        originalTransactionId: tx.id,
                        amount: tx.amount,
                        merchant: tx.merchant,
                        platform: tx.platform,
                        loggedAt: tx.createdAt
                    }
                }
            });

            // Update the journal entry with the report link and SCAMMED status
            await prisma.transactionJournal.update({
                where: { id },
                data: {
                    reportId: report.id,
                    status: 'SCAMMED',
                    riskScore: 100
                }
            });

            res.status(201).json({
                message: 'Transaction successfully converted to scam report',
                report
            });
        } catch (error) {
            next(error);
        }
    }
}
