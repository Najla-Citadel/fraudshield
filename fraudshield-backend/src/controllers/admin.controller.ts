import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';

export class AdminController {
    static async getAlerts(req: Request, res: Response, next: NextFunction) {
        try {
            // For now, return the Alert model. In the real app, this might be filtered.
            const alerts = await prisma.alert.findMany({
                orderBy: { createdAt: 'desc' },
            });
            res.json(alerts);
        } catch (error) {
            next(error);
        }
    }

    static async labelTransaction(req: Request, res: Response, next: NextFunction) {
        try {
            const { txId, label, alertId } = req.body;
            const userId = (req.user as any).id;

            await prisma.fraudLabel.create({
                data: {
                    txId,
                    label,
                    labeledBy: userId,
                },
            });

            if (alertId) {
                await prisma.alert.update({
                    where: { id: alertId },
                    data: { isRead: true }, // or add a 'processed' field to Alert model
                });
            }

            res.json({ message: 'Transaction labeled successfully' });
        } catch (error) {
            next(error);
        }
    }

    static async getTransaction(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            const tx = await prisma.transaction.findUnique({
                where: { id: id as string },
            });
            res.json(tx);
        } catch (error) {
            next(error);
        }
    }
}
