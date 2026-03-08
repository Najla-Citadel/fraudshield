import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { GamificationService } from '../services/gamification.service';

export class SubscriptionController {
    static async getPlans(req: Request, res: Response, next: NextFunction) {
        try {
            const plans = await prisma.subscriptionPlan.findMany({
                orderBy: { price: 'asc' },
            });
            res.json(plans);
        } catch (error) {
            next(error);
        }
    }

    static async getMySubscription(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;

            const subscription = await prisma.userSubscription.findFirst({
                where: { userId },
                include: { plan: true },
                orderBy: { startDate: 'desc' },
            });

            res.json(subscription);
        } catch (error) {
            next(error);
        }
    }

    static async createSubscription(req: Request, res: Response, next: NextFunction) {
        try {
            const { planId, endDate, paymentMethod } = req.body;
            const userId = (req.user as any).id;

            const subscription = await prisma.userSubscription.create({
                data: {
                    userId,
                    planId,
                    isActive: true,
                    startDate: new Date(),
                    endDate: new Date(endDate),
                },
                include: { plan: true },
            });

            res.status(201).json(subscription);
        } catch (error) {
            next(error);
        }
    }
}



export class PointsController {
    static async getMyPoints(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;

            const [profile, transactions] = await Promise.all([
                (prisma as any).profile.findUnique({ where: { userId } }),
                prisma.pointsTransaction.findMany({
                    where: { userId },
                    orderBy: { createdAt: 'desc' },
                })
            ]);

            const currentBalance = profile?.points ?? 0;
            const totalPoints = profile?.totalPoints ?? 0;
            const tierProgress = GamificationService.getTierProgress(totalPoints);

            res.json({
                totalPoints,
                currentBalance,
                ...tierProgress,
                transactions
            });
        } catch (error) {
            next(error);
        }
    }

    static async addPoints(req: Request, res: Response, next: NextFunction) {
        try {
            const { amount, description } = req.body;
            const userId = (req.user as any).id;

            const result = await GamificationService.awardPoints(
                userId,
                amount,
                description || 'Manual point adjustment'
            );

            res.status(201).json(result);
        } catch (error) {
            next(error);
        }
    }
}

export class BehavioralController {
    static async logEvent(req: Request, res: Response, next: NextFunction) {
        try {
            const { type, metadata } = req.body;
            const userId = (req.user as any).id;

            const event = await prisma.behavioralEvent.create({
                data: {
                    userId,
                    type,
                    metadata: metadata || {},
                },
            });

            res.status(201).json(event);
        } catch (error) {
            next(error);
        }
    }

    static async getMyEvents(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const limit = parseInt(req.query.limit as string) || 50;

            const events = await prisma.behavioralEvent.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
                take: limit,
            });

            res.json(events);
        } catch (error) {
            next(error);
        }
    }
}

export class SecurityScanController {
    static async saveScan(req: Request, res: Response, next: NextFunction) {
        try {
            const { totalAppsScanned, riskyApps } = req.body;
            const userId = (req.user as any).id;

            const scan = await prisma.securityScan.create({
                data: {
                    userId,
                    totalAppsScanned: parseInt(String(totalAppsScanned)) || 0,
                    riskyApps: riskyApps || [],
                },
            });

            res.status(201).json(scan);
        } catch (error) {
            next(error);
        }
    }

    static async getMyScans(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const limit = parseInt(req.query.limit as string) || 20;

            const scans = await prisma.securityScan.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
                take: limit,
            });

            res.json(scans);
        } catch (error) {
            next(error);
        }
    }
}

export class AppIntelligenceController {
    static async getIntelligence(req: Request, res: Response, next: NextFunction) {
        try {
            const packages = (req.query.packages as string || '').split(',').filter(p => p.length > 0);
            
            if (packages.length === 0) {
                return res.json([]);
            }

            const intelligence = await prisma.appReputation.findMany({
                where: {
                    packageName: { in: packages }
                }
            });

            res.json(intelligence);
        } catch (error) {
            next(error);
        }
    }

    static async recordAction(req: Request, res: Response, next: NextFunction) {
        try {
            const { packageName, action } = req.body; // action: "SAFE" | "REPORT"
            const userId = (req.user as any).id;

            if (!packageName || !['SAFE', 'REPORT'].includes(action)) {
                return res.status(400).json({ message: 'Invalid package name or action' });
            }

            // check for dup action
            const existingAction = await prisma.appActionLog.findUnique({
                where: {
                    userId_packageName_action: {
                        userId,
                        packageName,
                        action
                    }
                }
            });

            if (existingAction) {
                return res.status(409).json({ message: 'Action already recorded by this user' });
            }

            // Record action and update reputation in a transaction
            const result = await prisma.$transaction(async (tx) => {
                await tx.appActionLog.create({
                    data: { userId, packageName, action }
                });

                const currentRep = await tx.appReputation.findUnique({
                    where: { packageName }
                });

                const safeVotes = (currentRep?.safeVotes || 0) + (action === 'SAFE' ? 1 : 0);
                const threatReports = (currentRep?.threatReports || 0) + (action === 'REPORT' ? 1 : 0);
                
                // Simple score calc: Safe votes help, reports hurt.
                // Cap adjustment to [-30, 30]
                let adjustment = Math.floor(safeVotes / 2) - (threatReports * 3);
                adjustment = Math.max(-30, Math.min(30, adjustment));

                return await tx.appReputation.upsert({
                    where: { packageName },
                    create: {
                        packageName,
                        safeVotes,
                        threatReports,
                        globalScoreAdjustment: adjustment
                    },
                    update: {
                        safeVotes,
                        threatReports,
                        globalScoreAdjustment: adjustment
                    }
                });
            });

            res.status(201).json(result);
        } catch (error) {
            next(error);
        }
    }
}
