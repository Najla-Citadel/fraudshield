import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';

export class ReportController {
    static async submitReport(req: Request, res: Response, next: NextFunction) {
        try {
            const { type, category, description, evidence } = req.body;
            const userId = (req.user as any).id;

            const report = await prisma.scamReport.create({
                data: {
                    userId,
                    type,
                    category,
                    description,
                    evidence: evidence || {},
                    status: 'PENDING',
                },
            });

            res.status(201).json(report);
        } catch (error) {
            next(error);
        }
    }

    static async getMyReports(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;

            const reports = await prisma.scamReport.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
            });

            res.json(reports);
        } catch (error) {
            next(error);
        }
    }

    static async getReportDetails(req: Request, res: Response, next: NextFunction) {
        try {
            const id = req.params.id as string;
            const userId = (req.user as any).id;

            const report = await prisma.scamReport.findFirst({
                where: { id, userId },
            });

            if (!report) {
                return res.status(404).json({ message: 'Report not found' });
            }

            res.json(report);
        } catch (error) {
            next(error);
        }
    }
}
