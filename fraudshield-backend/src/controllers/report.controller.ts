import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { BadgeService } from '../services/badge.service';
import { SemakMuleService } from '../services/semak-mule.service';
import { AlertEngineService } from '../services/alert-engine.service';
import { GamificationService } from '../services/gamification.service';
import { RiskEvaluationService } from '../services/risk-evaluation.service';
import { EncryptionUtils } from '../utils/encryption';
import { ContentModerationService } from '../services/content-moderation.service';
import { io } from '../server';

/**
 * @openapi
 * tags:
 *   name: Reports
 *   description: Scam report management and public feed
 */
export class ReportController {
    private static readonly MAX_LIMIT = 100;

    /**
     * @openapi
     * /api/v1/reports:
     *   post:
     *     summary: Submit a new scam report
     *     tags: [Reports]
     *     security:
     *       - bearerAuth: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required: [type, category, description, target]
     *             properties:
     *               type: { type: string, enum: [phone, bank, doc, link] }
     *               category: { type: string }
     *               description: { type: string }
     *               target: { type: string }
     *               isPublic: { type: boolean }
     *               latitude: { type: number }
     *               longitude: { type: number }
     *               evidence: { type: object }
     *     responses:
     *       201:
     *         description: Report submitted successfully
     */
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

            // 2.3 Duplicate Report Detection
            const encryptedTarget = EncryptionUtils.deterministicEncrypt(target);
            const duplicate = await (prisma as any).scamReport.findFirst({
                where: {
                    userId,
                    target: encryptedTarget,
                    createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
                },
            });

            if (duplicate) {
                return res.status(409).json({
                    message: 'You have already reported this target in the last 24 hours.',
                    reportId: duplicate.id,
                });
            }

            // Step 1.5: Validate evidence JSON schema
            const MAX_EVIDENCE_SIZE = 50 * 1024; // 50KB max
            const evidenceStr = JSON.stringify(evidence || {});

            if (evidenceStr.length > MAX_EVIDENCE_SIZE) {
                return res.status(400).json({ message: 'Evidence data exceeds maximum size (50KB)' });
            }

            // Whitelist allowed keys
            const ALLOWED_EVIDENCE_KEYS = [
                'smsContent', 'message', 'callerName', 'screenshots', 'notes',
                'target_type', 'phone', 'bank_name', 'account_number', 'platform',
                'handle', 'url', 'evidence_url', 'location_text'
            ];
            if (evidence && typeof evidence === 'object') {
                const keys = Object.keys(evidence);
                const invalidKeys = keys.filter(k => !ALLOWED_EVIDENCE_KEYS.includes(k));
                if (invalidKeys.length > 0) {
                    return res.status(400).json({
                        message: `Invalid evidence fields: ${invalidKeys.join(', ')}`,
                    });
                }

                // Validate screenshots array
                if (evidence.screenshots && (!Array.isArray(evidence.screenshots) || (evidence.screenshots as any[]).length > 5)) {
                    return res.status(400).json({ message: 'Maximum 5 screenshot references allowed' });
                }

                // Validate text field lengths
                if (evidence.smsContent && (evidence.smsContent as string).length > 2000) {
                    return res.status(400).json({ message: 'SMS content exceeds maximum length (2000 chars)' });
                }

                if (evidence.message && (evidence.message as string).length > 2000) {
                    return res.status(400).json({ message: 'Message content exceeds maximum length (2000 chars)' });
                }
            }

            const report = await (prisma as any).scamReport.create({
                data: {
                    userId,
                    type,
                    category,
                    description,
                    target: EncryptionUtils.deterministicEncrypt(target),
                    isPublic: false, // Force false for moderation
                    latitude,
                    longitude,
                    evidence: {
                        ...(evidence || {}),
                        _moderation: await ContentModerationService.screenContent(description),
                        _extractedEntities: await ContentModerationService.extractEntities(description),
                        _device: (req as any).deviceId || 'unknown',
                    },
                    status: 'PENDING',
                },
            });

            // Invalidate Redis cache for this target
            await RiskEvaluationService.invalidateCache(type, target).catch(err => {
                console.error('Failed to invalidate cache:', err);
            });

            res.status(201).json({
                ...report,
                message: 'Report submitted for moderation. Points will be awarded upon approval.',
                pointsAwarded: 0
            });
        } catch (error) {
            next(error);
        }
    }

    static async getMyReports(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { limit = '20', offset = '0' } = req.query;

            const limitNum = Math.min(parseInt(limit as string, 10) || 20, ReportController.MAX_LIMIT);
            const offsetNum = Math.max(parseInt(offset as string, 10) || 0, 0);

            const [reports, total] = await Promise.all([
                prisma.scamReport.findMany({
                    where: { userId, deletedAt: null },
                    orderBy: { createdAt: 'desc' },
                    take: limitNum,
                    skip: offsetNum,
                }).then(reports => reports.map(r => ({ ...r, target: EncryptionUtils.decrypt(r.target || '') }))),
                prisma.scamReport.count({ where: { userId, deletedAt: null } }),
            ]);

            res.json({
                results: reports,
                total,
                hasMore: offsetNum + limitNum < total,
                limit: limitNum,
                offset: offsetNum,
            });
        } catch (error) {
            next(error);
        }
    }

    static async getReportDetails(req: Request, res: Response, next: NextFunction) {
        try {
            const id = req.params.id as string;
            const userId = (req.user as any).id;

            const report = await (prisma as any).scamReport.findUnique({
                where: { id, deletedAt: null },
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
                target: EncryptionUtils.decrypt(report.target || ''),
                reporterTrust: {
                    score: profile?.reputation ?? 0,
                    badges: Array.isArray(badges) ? badges : [],
                },
                user: undefined, // Don't expose sensitive user info
                userId: isOwner ? report.userId : undefined,
                _count: {
                    verifications: report.verifications.length,
                    upvotes: report.verifications.filter((v: any) => v.isSame).length,
                    downvotes: report.verifications.filter((v: any) => !v.isSame).length,
                },
                myVote: report.verifications.find((v: any) => v.userId === userId)?.isSame === true ? 'up' : 
                         report.verifications.find((v: any) => v.userId === userId)?.isSame === false ? 'down' : null,
            };

            res.json(response);
        } catch (error) {
            next(error);
        }
    }

    /**
     * @openapi
     * /api/v1/reports/public:
     *   get:
     *     summary: Get public scam report feed
     *     tags: [Reports]
     *     responses:
     *       200:
     *         description: Successfully retrieved feed
     */
    static async getPublicFeed(req: Request, res: Response, next: NextFunction) {
        try {
            const { limit = '20', offset = '0', lat, lng, radius, category, search } = req.query;
            const limitNum = Math.min(parseInt(limit as string, 10) || 20, ReportController.MAX_LIMIT);
            const offsetNum = Math.max(parseInt(offset as string, 10) || 0, 0);

            let whereClause: any = { isPublic: true, deletedAt: null };

            if (category) {
                whereClause.category = category as string;
            }

            if (search) {
                whereClause.description = {
                    contains: search as string,
                    mode: 'insensitive',
                };
            }

            // Optional localized filtering
            if (lat && lng && radius) {
                const latitude = parseFloat(lat as string);
                const longitude = parseFloat(lng as string);
                const radiusKm = parseFloat(radius as string);

                if (!isNaN(latitude) && !isNaN(longitude) && !isNaN(radiusKm)) {
                    // Rough bounding box for better performance before complex math
                    const latDegreeSearch = radiusKm / 111.32; // 1 degree = ~111km
                    const lngDegreeSearch = radiusKm / (111.32 * Math.cos(latitude * (Math.PI / 180)));

                    whereClause = {
                        ...whereClause,
                        latitude: {
                            gte: latitude - latDegreeSearch,
                            lte: latitude + latDegreeSearch,
                        },
                        longitude: {
                            gte: longitude - lngDegreeSearch,
                            lte: longitude + lngDegreeSearch,
                        },
                    };
                }
            }

            const [reports, total] = await Promise.all([
                (prisma as any).scamReport.findMany({
                    where: whereClause,
                    include: {
                        verifications: true,
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
                    take: limitNum,
                    skip: offsetNum,
                }).then(reports => reports.map(r => ({ ...r, target: r.target }))), // Keep raw target for now, redact in final map
                (prisma as any).scamReport.count({ where: whereClause }),
            ]);

            // Anonymize sensitive fields
            const redactedReports = reports.map((report: any) => {
                const profile = report.user?.profile;

                let badges = profile?.badges;
                if (typeof badges === 'string') {
                    try { badges = JSON.parse(badges); } catch (e) { badges = []; }
                }

                return {
                    ...report,
                    target: redactTarget(EncryptionUtils.decrypt(report.target || ''), report.type),
                    reporterTrust: {
                        score: profile?.reputation ?? 0,
                        badges: Array.isArray(badges) ? badges : [],
                    },
                    _count: {
                        verifications: report.verifications.length,
                        upvotes: report.verifications.filter((v: any) => v.isSame).length,
                        downvotes: report.verifications.filter((v: any) => !v.isSame).length,
                    },
                    user: undefined, // Don't expose user info
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
                deletedAt: null,
                AND: [],
            };

            // Text search across multiple fields
            if (query && typeof query === 'string' && query.trim()) {
                const encryptedQuery = EncryptionUtils.deterministicEncrypt(query as string);
                whereClause.AND.push({
                    OR: [
                        { description: { contains: query, mode: 'insensitive' } },
                        { target: encryptedQuery },
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

            const limitNum = Math.min(parseInt(limit as string, 10) || 20, ReportController.MAX_LIMIT);
            const offsetNum = Math.max(parseInt(offset as string, 10) || 0, 0);

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
                }).then(reports => reports.map(r => ({ ...r, target: r.target }))), // Keep raw target for now, redact in final map
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
                    target: redactTarget(EncryptionUtils.decrypt(report.target || ''), report.type),
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

            // 1. Fetch report and user profile for validation
            const [report, userProfile] = await Promise.all([
                (prisma as any).scamReport.findUnique({
                    where: { id: reportId },
                    select: { userId: true, status: true, isPublic: true },
                }),
                (prisma as any).profile.findUnique({
                    where: { userId },
                    select: { reputation: true },
                }),
            ]);

            if (!report) {
                return res.status(404).json({ message: 'Report not found' });
            }

            // Security Check: Cannot verify own report
            if (report.userId === userId) {
                return res.status(403).json({ message: 'You cannot verify your own reports' });
            }

            // Security Check: Report must be publicly accessible
            if (!report.isPublic) {
                return res.status(403).json({ message: 'Only public reports can be community-verified' });
            }

            // Security Check: Minimum reputation to verify others
            const minReputation = 20;
            if ((userProfile?.reputation ?? 0) < minReputation) {
                return res.status(403).json({
                    message: `Increasing trust required. You need at least ${minReputation} reputation to verify reports.`,
                });
            }

            // 2. Create or update the verification
            const verification = await prisma.verification.upsert({
                where: {
                    reportId_userId: { reportId, userId },
                },
                update: { isSame },
                create: { reportId, userId, isSame },
            });

            // 3. Reward the verifier with Shield Points (with daily cap)
            const today = new Date();
            today.setHours(0, 0, 0, 0);

            const todayVerifications = await prisma.verification.count({
                where: {
                    userId,
                    createdAt: { gte: today },
                },
            });

            const DAILY_VERIFICATION_CAP = 10; // Max 10 rewarded votes per day

            if (todayVerifications <= DAILY_VERIFICATION_CAP) {
                await GamificationService.awardPoints(
                    userId,
                    10,
                    `Verified report ${reportId}`
                );
            }

            // 4. Reward the original reporter with Reputation if verified as 'Same'
            if (isSame) {
                // Daily reputation gain cap: max 20 upvotes per report per day
                const todayUpvotes = await (prisma as any).verification.count({
                    where: {
                        reportId,
                        isSame: true,
                        createdAt: { gte: today },
                    },
                });

                const DAILY_REP_CAP = 20;
                if (todayUpvotes <= DAILY_REP_CAP) {
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
                }

                // Evaluate badges for the reporter
                await BadgeService.evaluateBadges(report.userId);
            } else {
                // Potential penalty logic if many people dispute this report
                const downvoteCount = await (prisma as any).verification.count({
                    where: { reportId, isSame: false }
                });

                if (downvoteCount >= 5) {
                    // Reputation floor: never go below 0
                    const reporterProfile = await (prisma as any).profile.findUnique({
                        where: { userId: report.userId },
                        select: { reputation: true },
                    });
                    const currentRep = reporterProfile?.reputation ?? 0;
                    if (currentRep > 0) {
                        await (prisma as any).profile.update({
                            where: { userId: report.userId },
                            data: { reputation: { decrement: Math.min(2, currentRep) } }
                        });
                    }
                }
            }

            res.json(verification);
        } catch (error) {
            next(error);
        }
    }

    static async lookupReport(req: Request, res: Response, next: NextFunction) {
        try {
            const { type, value } = req.query;

            if (!type || !value || typeof value !== 'string') {
                return res.status(400).json({ message: 'Missing type or value query parameters' });
            }

            // Build query based on target match
            const whereClause: any = {
                target: EncryptionUtils.deterministicEncrypt(value),
                deletedAt: null,
            };

            const reports = await (prisma as any).scamReport.findMany({
                where: {
                    ...whereClause,
                    status: 'VERIFIED', // Only count verifications for verified reports
                    isPublic: true,
                },
                include: {
                    _count: {
                        select: { verifications: true },
                    },
                },
                orderBy: { createdAt: 'desc' },
            }).then(reports => reports.map(r => ({ ...r, target: EncryptionUtils.decrypt(r.target || '') })));

            const totalCount = reports.length;

            // Aggregate metrics
            let verifiedCount = 0;
            const categorySet = new Set<string>();
            let highestRisk = false;

            for (const report of reports) {
                if (report._count.verifications >= 2) {
                    verifiedCount++;
                }
                if (report.category) {
                    categorySet.add(report.category);
                }

                // If any report has >= 5 verifications, we consider it high risk immediately
                if (report._count.verifications >= 5) {
                    highestRisk = true;
                }
            }

            const categories = Array.from(categorySet);
            const lastReported = totalCount > 0 ? reports[0]?.createdAt : undefined;

            // Determine Risk Level
            let riskLevel = 'low';
            let recommendation = '';
            const sources: string[] = [];

            // 1. Check Community Database
            if (totalCount > 0) {
                sources.push('community');
                if (totalCount >= 3 || verifiedCount >= 1 || highestRisk) {
                    riskLevel = 'high';
                    recommendation = `This ${type} has been reported ${totalCount} times. Proceed with extreme caution.`;
                } else {
                    riskLevel = 'medium';
                    recommendation = `This ${type} has ${totalCount} unverified report(s). Verify the recipient before paying.`;
                }
            }

            // 2. Check Official Databases (CCID Semak Mule API mock)
            if (type === 'phone' || type === 'bank') {
                try {
                    const officialMuleCheck = await SemakMuleService.checkTarget(type as any, value as string);

                    if (officialMuleCheck.found && officialMuleCheck.riskLevel === 'high') {
                        // Overwrite community risk to HIGH if official API flags it
                        riskLevel = 'high';
                        recommendation = officialMuleCheck.recommendation; // Use official text
                    }

                    // Add CCID to sources list (it was checked)
                    sources.push('ccid');
                } catch (apiError) {
                    console.warn(`[Lookup API] CCID connection failed for ${value}:`, apiError);
                    // Do not add 'ccid' to the sources list, keep the community risk level
                    // so the app gracefully degrades to crowdsourced data instead of crashing.
                }
            }

            if (totalCount === 0 && riskLevel === 'low') {
                recommendation = 'No community reports found. Proceed with standard caution.';
            }

            let journalId: string | undefined;

            // Log to TransactionJournal if user is authenticated
            const userId = (req.user as any)?.id;
            if (userId && (type === 'phone' || type === 'bank' || type === 'doc')) {
                const dbCheckType = type === 'phone' ? 'PHONE' : type === 'bank' ? 'BANK' : 'DOC';
                let score = 0;
                let status = 'SAFE';

                if (riskLevel === 'high') {
                    score = 90;
                    status = 'BLOCKED';
                } else if (riskLevel === 'medium') {
                    score = 60;
                    status = 'SUSPICIOUS';
                }

                const journal = await (prisma as any).transactionJournal.create({
                    data: {
                        userId,
                        checkType: dbCheckType as any,
                        target: value as string,
                        riskScore: score,
                        status: status,
                        metadata: {
                            found: (totalCount || 0) > 0 || riskLevel === 'high',
                            riskLevel,
                            communityReports: totalCount,
                            verifiedReports: verifiedCount,
                            categories,
                        }
                    }
                });
                journalId = journal.id;
            }

            res.json({
                found: (totalCount || 0) > 0 || riskLevel === 'high',
                riskLevel,
                communityReports: totalCount,
                verifiedReports: verifiedCount,
                categories,
                lastReported,
                sources,
                recommendation,
                journalId,
            });

        } catch (error) {
            next(error);
        }
    }

    /**
     * @openapi
     * /api/v1/reports/lookup-feedback:
     *   post:
     *     summary: Submit feedback for a lookup
     *     tags: [Reports]
     *     security:
     *       - bearerAuth: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required: [journalId, wasHelpful]
     *             properties:
     *               journalId:
     *                 type: string
     *               wasHelpful:
     *                 type: boolean
     *     responses:
     *       200:
     *         description: Feedback submitted successfully
     */
    static async submitLookupFeedback(req: Request, res: Response, next: NextFunction) {
        try {
            const { journalId, wasHelpful } = req.body;
            const userId = (req.user as any).id;

            if (!journalId) {
                return res.status(400).json({ message: 'Journal ID is required' });
            }

            const updatedJournal = await (prisma as any).transactionJournal.update({
                where: {
                    id: journalId,
                    userId,
                },
                data: {
                    wasHelpful: wasHelpful === true,
                },
            });

            res.json({ success: true, journalId: updatedJournal.id });
        } catch (error) {
            next(error);
        }
    }

    static flagContent = async (req: Request, res: Response) => {
        try {
            const { targetId, type, reason } = req.body;
            const userId = (req.user as any).id;

            if (!['report', 'comment'].includes(type)) {
                return res.status(400).json({ message: 'Invalid flag type. Must be "report" or "comment".' });
            }

            if (!targetId || !reason) {
                return res.status(400).json({ message: 'Target ID and reason are required.' });
            }

            const flag = await (prisma as any).contentFlag.upsert({
                where: {
                    targetId_userId_type: {
                        targetId,
                        userId,
                        type,
                    },
                },
                update: { reason, status: 'PENDING' },
                create: {
                    targetId,
                    userId,
                    type,
                    reason,
                },
            });

            // Auto-hide logic: if 3+ reports, hide it
            const flagCount = await (prisma as any).contentFlag.count({
                where: { targetId, type, status: 'PENDING' },
            });

            if (flagCount >= 3) {
                if (type === 'report') {
                    await (prisma as any).scamReport.update({
                        where: { id: targetId },
                        data: { isPublic: false },
                    });
                } else if (type === 'comment') {
                    await (prisma as any).comment.update({
                        where: { id: targetId },
                        data: { text: '[This comment has been hidden due to community reports]' },
                    });
                }
            }

            res.json({
                message: 'Content flagged successfully. Our moderators will review it shortly.',
                flagId: flag.id,
                autoHidden: flagCount >= 3
            });
        } catch (error) {
            console.error('Flag error:', error);
            res.status(500).json({ message: 'Internal server error' });
        }
    };
}

function redactTarget(val: string, type?: string): string {
    if (!val) return '****';

    // Phone: show first 3 + last 2 → "012****89"
    if (type === 'phone' && val.length > 5) {
        return `${val.substring(0, 3)}****${val.substring(val.length - 2)}`;
    }

    // Bank: show last 4 digits → "****1234"
    if (type === 'bank' && val.length > 4) {
        return `****${val.substring(val.length - 4)}`;
    }

    // URL: show domain only → "example.com/****"
    if (type === 'link' || type === 'url') {
        try {
            const url = new URL(val.startsWith('http') ? val : `https://${val}`);
            return `${url.hostname}/****`;
        } catch {
            return val.length > 10 ? `${val.substring(0, 10)}****` : val;
        }
    }

    // Default: show first 3 + last 2
    if (val.length > 5) {
        return `${val.substring(0, 3)}****${val.substring(val.length - 2)}`;
    }
    return '****';
}
