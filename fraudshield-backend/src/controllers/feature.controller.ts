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
                orderBy: { createdAt: 'desc' },
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
                    status: 'ACTIVE',
                    startDate: new Date(),
                    endDate: new Date(endDate),
                    paymentMethod: paymentMethod || 'CREDIT_CARD',
                    autoRenew: true,
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
            const { amount, type, description } = req.body;
            const userId = (req.user as any).id;

            const transaction = await prisma.pointsTransaction.create({
                data: {
                    userId,
                    amount,
                    type: type || 'EARN',
                    description: description || '',
                },
            });

            res.status(201).json(transaction);
        } catch (error) {
            next(error);
        }
    }
}
