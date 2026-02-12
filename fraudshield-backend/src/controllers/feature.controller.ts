import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';

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

            const transactions = await prisma.pointsTransaction.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
            });

            const totalPoints = transactions.reduce((sum, tx) => sum + tx.amount, 0);

            res.json({ totalPoints, transactions });
        } catch (error) {
            next(error);
        }
    }

    static async addPoints(req: Request, res: Response, next: NextFunction) {
        try {
            const { amount, description } = req.body;
            const userId = (req.user as any).id;

            const transaction = await prisma.pointsTransaction.create({
                data: {
                    userId,
                    amount,
                    description: description || '',
                },
            });

            res.status(201).json(transaction);
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
