import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { EncryptionUtils } from '../utils/encryption';
import { MacauScamService } from '../services/macau-scam.service';
import { AlertService } from '../services/alert.service';
import { MuleDetectionService } from '../services/mule-detection.service';

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
                }).then(txs => txs.map(tx => ({ ...tx, target: EncryptionUtils.decrypt(tx.target || '') }))),
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

            res.json({
                ...transaction,
                target: EncryptionUtils.decrypt(transaction.target || ''),
            });
        } catch (error) {
            next(error);
        }
    }

    static async logTransaction(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const {
                amount,
                merchant,
                target,
                paymentMethod,
                platform,
                notes,
                checkType
            } = req.body;

            // 1. Run Pre-Check
            let preCheck = {
                riskLevel: 'unknown',
                communityReports: 0,
                recommendation: 'No community reports found. Proceed with standard caution.',
            };

            let riskScore = 0;
            let status = 'SAFE';

            if (target) {
                // Since we use deterministic encryption for target, we must search by the encrypted value
                const encryptedTarget = EncryptionUtils.deterministicEncrypt(target);
                const reportsCount = await prisma.scamReport.count({
                    where: { target: encryptedTarget } // exact match only
                });

                if (reportsCount > 0) {
                    preCheck = {
                        riskLevel: reportsCount >= 3 ? 'high' : 'medium',
                        communityReports: reportsCount,
                        recommendation: `${reportsCount} previous report(s) found for this recipient. Consider using platform escrow instead.`
                    };
                    riskScore = reportsCount >= 3 ? 90 : 60;
                    status = reportsCount >= 3 ? 'BLOCKED' : 'SUSPICIOUS';
                }
            }

            const transaction = await prisma.transactionJournal.create({
                data: {
                    userId,
                    checkType: checkType || 'MANUAL',
                    target: (target || merchant) ? EncryptionUtils.deterministicEncrypt(target || merchant) : null,
                    amount: amount ? parseFloat(amount) : null,
                    merchant,
                    paymentMethod,
                    platform,
                    notes,
                    riskScore,
                    status,
                    metadata: {
                        source: 'manual_entry',
                        loggedAt: new Date(),
                    }
                }
            });

            // 2. Perform Macau Scam Pattern Analysis
            const macauEvaluation = await MacauScamService.evaluate(userId, notes, transaction.id);
            if (macauEvaluation.isMacauScam && macauEvaluation.confidence === 'critical') {
                // Auto-create alert with MACAU_SCAM category
                await prisma.alert.create({
                    data: {
                        userId,
                        title: '🔴 Critical Macau Scam Alert',
                        message: macauEvaluation.recommendation,
                        severity: 'CRITICAL',
                        category: 'MACAU_SCAM',
                        txId: transaction.id,
                        riskScore: macauEvaluation.riskScore,
                        decision: 'BLOCKED',
                        metadata: {
                            signals: macauEvaluation.signals,
                            emergencyContacts: macauEvaluation.emergencyContacts
                        }
                    }
                });

                // Update transaction status
                await prisma.transactionJournal.update({
                    where: { id: transaction.id },
                    data: { status: 'BLOCKED', riskScore: macauEvaluation.riskScore }
                });
            }

            // 3. Perform Mule Account Velocity Analysis
            const muleEvaluation = await MuleDetectionService.evaluate(userId, amount ? parseFloat(amount) : null, target || merchant);
            if (muleEvaluation.isMule) {
                // Auto-create alert with MULE_ACCOUNT category
                const primaryRule = muleEvaluation.triggeredRules[0] || 'Activity';
                await prisma.alert.create({
                    data: {
                        userId,
                        title: `🔴 Mule Alert: ${primaryRule}`,
                        message: muleEvaluation.recommendation,
                        severity: muleEvaluation.confidence === 'critical' ? 'CRITICAL' : 'HIGH',
                        category: 'MULE_ACCOUNT',
                        txId: transaction.id,
                        riskScore: muleEvaluation.riskScore,
                        decision: 'SUSPICIOUS',
                        metadata: {
                            triggeredRules: muleEvaluation.triggeredRules
                        }
                    }
                });

                // Update transaction status
                await prisma.transactionJournal.update({
                    where: { id: transaction.id },
                    data: { status: 'SUSPICIOUS', riskScore: Math.max(transaction.riskScore, muleEvaluation.riskScore) }
                });
            }

            res.status(201).json({
                transaction: {
                    ...transaction,
                    target: EncryptionUtils.decrypt(transaction.target || '')
                },
                preCheck,
                macauEvaluation,
                muleEvaluation
            });
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
                    target: tx.target, // already encrypted in journal
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
