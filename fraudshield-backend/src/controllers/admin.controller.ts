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

    static async getUsers(req: Request, res: Response, next: NextFunction) {
        try {
            const users = await prisma.user.findMany({
                select: {
                    id: true,
                    email: true,
                    fullName: true,
                    role: true,
                    createdAt: true,
                    emailVerified: true,
                } as any,
                orderBy: { createdAt: 'desc' },
            });
            res.json(users);
        } catch (error) {
            next(error);
        }
    }

    static async updateUserRole(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            const { role } = req.body;

            const updatedUser = await prisma.user.update({
                where: { id: id as string },
                data: { role },
                select: { id: true, role: true },
            });

            res.json(updatedUser);
        } catch (error) {
            next(error);
        }
    }

    static async getReports(req: Request, res: Response, next: NextFunction) {
        try {
            const reports = await prisma.scamReport.findMany({
                include: {
                    user: {
                        select: {
                            fullName: true,
                            email: true,
                        }
                    }
                },
                orderBy: { createdAt: 'desc' },
            });
            res.json(reports);
        } catch (error) {
            next(error);
        }
    }

    static async updateReportStatus(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            const { status } = req.body;

            const updatedReport = await prisma.scamReport.update({
                where: { id: id as string },
                data: { status },
            });

            res.json(updatedReport);
        } catch (error) {
            next(error);
        }
    }

    static async getStats(req: Request, res: Response, next: NextFunction) {
        try {
            const [userCount, reportCount, pendingReports] = await Promise.all([
                prisma.user.count(),
                prisma.scamReport.count(),
                prisma.scamReport.count({ where: { status: 'pending' } }),
            ]);

            res.json({
                totalUsers: userCount,
                totalReports: reportCount,
                pendingReports: pendingReports,
            });
        } catch (error) {
            next(error);
        }
    }
}
