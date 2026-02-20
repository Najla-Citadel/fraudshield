import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { BadgeService } from '../services/badge.service';


export class ReportController {
    static async submitReport(req: Request, res: Response, next: NextFunction) {
        try {
            const { type, category, description, evidence, target, isPublic, latitude, longitude } = req.body;
            const userId = (req.user as any).id;

            // Ensure user has a profile (needed for public feed display)
            await (prisma as any).profile.upsert({
                where: { userId },
                update: {},
                create: {
                    userId,
                    points: 0,
                    reputation: 0,
                    badges: [],
                    avatar: 'Felix', // Default avatar
                },
            });

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

            // Award points for submitting a report
            let newBadges: string[] = [];
            if (isPublic) {
                await (prisma as any).profile.update({
                    where: { userId },
                    data: {
                        points: { increment: 10 },
                    },
                });

                await (prisma as any).pointsTransaction.create({
                    data: {
                        userId,
                        amount: 10,
                        description: `Submitted public scam report`,
                    },
                });

                // Evaluate badges
                newBadges = await BadgeService.evaluateBadges(userId);
            }

            res.status(201).json({ ...report, newBadges });
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

            const report = await (prisma as any).scamReport.findUnique({
                where: { id },
                include: {
                    verifications: true,
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
            });

            if (!report) {
                return res.status(404).json({ message: 'Report not found' });
            }

            // Authorization: User must own the report OR it must be public
            if (report.userId !== userId && !report.isPublic) {
                return res.status(403).json({ message: 'Access denied' });
            }

            // Anonymize for non-owners if it's a public view
            const isOwner = report.userId === userId;
            const profile = report.user?.profile;

            let badges = profile?.badges;
            if (typeof badges === 'string') {
                try { badges = JSON.parse(badges); } catch (e) { badges = []; }
            }

            const response = {
                ...report,
                target: report.target,
                reporterTrust: {
                    score: profile?.reputation ?? 0,
                    badges: Array.isArray(badges) ? badges : [],
                },
                user: undefined, // Don't expose sensitive user info
                userId: isOwner ? report.userId : undefined,
                _count: {
                    verifications: report.verifications.length
                }
            };

            res.json(response);
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
                    target: report.target,
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

    static async searchReports(req: Request, res: Response, next: NextFunction) {
        try {
            const {
                q: query,
                category,
                dateFrom,
                dateTo,
                minVerifications,
                sortBy = 'newest',
                limit = '20',
                offset = '0',
            } = req.query;

            // Build dynamic where clause
            const whereClause: any = {
                isPublic: true,
                AND: [],
            };

            // Text search across multiple fields
            if (query && typeof query === 'string' && query.trim()) {
                whereClause.AND.push({
                    OR: [
                        { description: { contains: query, mode: 'insensitive' } },
                        { target: { contains: query, mode: 'insensitive' } },
                        { category: { contains: query, mode: 'insensitive' } },
                    ],
                });
            }

            // Category filter
            if (category && typeof category === 'string') {
                whereClause.AND.push({ category });
            }

            // Date range filters
            if (dateFrom && typeof dateFrom === 'string') {
                whereClause.AND.push({
                    createdAt: { gte: new Date(dateFrom) },
                });
            }

            if (dateTo && typeof dateTo === 'string') {
                whereClause.AND.push({
                    createdAt: { lte: new Date(dateTo) },
                });
            }

            // Remove empty AND array if no filters
            if (whereClause.AND.length === 0) {
                delete whereClause.AND;
            }

            const limitNum = parseInt(limit as string, 10);
            const offsetNum = parseInt(offset as string, 10);

            // Dynamic sort logic
            let orderByClause: any;
            switch (sortBy) {
                case 'verified':
                    // Sort by verification count (most verified first)
                    orderByClause = { verifications: { _count: 'desc' } };
                    break;
                case 'trust':
                    // Sort by reporter trust score (highest first)
                    orderByClause = { user: { profile: { reputation: 'desc' } } };
                    break;
                case 'newest':
                default:
                    // Sort by creation date (newest first)
                    orderByClause = { createdAt: 'desc' };
                    break;
            }

            // Fetch reports with filters
            const [reports, total] = await Promise.all([
                (prisma as any).scamReport.findMany({
                    where: whereClause,
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
                    orderBy: orderByClause,
                    take: limitNum,
                    skip: offsetNum,
                }),
                (prisma as any).scamReport.count({ where: whereClause }),
            ]);

            // Filter by minimum verifications if specified
            let filteredReports = reports;
            if (minVerifications && typeof minVerifications === 'string') {
                const minCount = parseInt(minVerifications, 10);
                filteredReports = reports.filter(
                    (report: any) => report._count.verifications >= minCount
                );
            }

            // Anonymize sensitive fields
            const redactedReports = filteredReports.map((report: any) => {
                const profile = report.user?.profile;

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
                    target: report.target,
                    reporterTrust: {
                        score: profile?.reputation ?? 0,
                        badges: Array.isArray(badges) ? badges : [],
                    },
                    user: undefined,
                    userId: undefined,
                };
            });

            res.json({
                results: redactedReports,
                total,
                hasMore: offsetNum + limitNum < total,
                limit: limitNum,
                offset: offsetNum,
            });
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

                // Evaluate badges for the reporter
                await BadgeService.evaluateBadges(report.userId);
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
