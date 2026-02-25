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
