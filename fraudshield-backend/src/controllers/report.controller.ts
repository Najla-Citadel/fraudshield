import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';

export class ReportController {
    static async submitReport(req: Request, res: Response, next: NextFunction) {
        try {
            const { type, category, description, evidence, target, isPublic, latitude, longitude } = req.body;
            const userId = (req.user as any).id;

            const report = await (prisma as any).scamReport.create({
                data: {
                    userId,
                    type,
                    category,
                    description,
                    target,
                    isPublic: isPublic || false,
                    latitude,
                    longitude,
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

            const report = await (prisma as any).scamReport.findFirst({
                where: { id, userId },
                include: {
                    verifications: true,
                },
            });

            if (!report) {
                return res.status(404).json({ message: 'Report not found' });
            }

            res.json(report);
        } catch (error) {
            next(error);
        }
    }

    static async getPublicFeed(req: Request, res: Response, next: NextFunction) {
        try {
            const reports = await (prisma as any).scamReport.findMany({
                where: { isPublic: true },
                include: {
                    _count: {
                        select: { verifications: true },
                    },
                    user: {
                        select: {
                            profile: {
                                select: {
                                    reputation: true,
                                    badges: true,
                                },
                            },
                        },
                    },
                },
                orderBy: { createdAt: 'desc' },
            });

            // Anonymize sensitive fields
            const redactedReports = reports.map((report) => {
                const profile = report.user?.profile;
                if (!profile) {
                    console.warn(`[PublicFeed] Report ${report.id} is missing reporter profile data.`);
                }

                // Ensure badges is an array (sometimes stored as stringified JSON in DB)
                let badges = profile?.badges;
                if (typeof badges === 'string') {
                    try {
                        badges = JSON.parse(badges);
                    } catch (e) {
                        badges = [];
                    }
                }

                return {
                    ...report,
                    target: report.target ? redactedValue(report.target) : null,
                    reporterTrust: {
                        score: profile?.reputation ?? 0,
                        badges: Array.isArray(badges) ? badges : [],
                    },
                    user: undefined, // Don't expose user info
                    userId: undefined,
                };
            });

            res.json(redactedReports);
        } catch (error) {
            next(error);
        }
    }

    static async verifyReport(req: Request, res: Response, next: NextFunction) {
        try {
            const { reportId, isSame } = req.body;
            const userId = (req.user as any).id;

            // 1. Create or update the verification
            const verification = await (prisma as any).verification.upsert({
                where: {
                    id: `${reportId}-${userId}`,
                },
                update: { isSame },
                create: {
                    id: `${reportId}-${userId}`,
                    reportId,
                    userId,
                    isSame,
                },
            });

            // 2. Reward the verifier with Shield Points
            await (prisma as any).profile.upsert({
                where: { userId },
                update: {
                    points: { increment: 10 },
                },
                create: {
                    userId,
                    points: 10,
                    avatar: 'Felix', // Default avatar
                },
            });

            await (prisma as any).pointsTransaction.create({
                data: {
                    userId,
                    amount: 10,
                    description: `Verified report ${reportId}`,
                },
            });

            // 3. Reward the original reporter with Reputation if verified as 'Same'
            const report = await (prisma as any).scamReport.findUnique({
                where: { id: reportId },
                select: { userId: true },
            });

            if (report && isSame && report.userId !== userId) {
                await (prisma as any).profile.upsert({
                    where: { userId: report.userId },
                    update: {
                        reputation: { increment: 5 },
                    },
                    create: {
                        userId: report.userId,
                        reputation: 5,
                        avatar: 'Felix',
                    },
                });

                // Check if they earned a new badge (Simple threshold logic)
                const reporterProfile = await (prisma as any).profile.findUnique({
                    where: { userId: report.userId },
                });

                if (reporterProfile) {
                    let currentBadges = (reporterProfile.badges as any[]) || [];
                    if (reporterProfile.reputation >= 50 && !currentBadges.includes('Elite Sentinel')) {
                        currentBadges.push('Elite Sentinel');
                        await (prisma as any).profile.update({
                            where: { userId: report.userId },
                            data: {
                                badges: currentBadges,
                            },
                        });
                    }
                }
            }

            res.json(verification);
        } catch (error) {
            next(error);
        }
    }
}

function redactedValue(val: string): string {
    if (val.includes('@')) {
        const [user, domain] = val.split('@');
        return `${user[0]}***@${domain}`;
    }
    if (val.length > 4) {
        return `${val.substring(0, 3)}****${val.substring(val.length - 2)}`;
    }
    return '****';
}
