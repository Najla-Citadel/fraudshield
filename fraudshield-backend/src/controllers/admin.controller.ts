import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { AuditService } from '../services/audit.service';

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

            await AuditService.logAction({
                adminId: userId,
                action: 'LABEL_TRANSACTION',
                targetType: 'Transaction',
                targetId: txId,
                payload: { label, alertId }
            });

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
                    subscriptions: {
                        where: {
                            isActive: true,
                            endDate: { gt: new Date() }
                        },
                        include: {
                            plan: true
                        },
                        orderBy: { startDate: 'desc' },
                        take: 1
                    }
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

            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'UPDATE_USER_ROLE',
                targetType: 'User',
                targetId: id as string,
                payload: { role }
            });

            res.json(updatedUser);
        } catch (error) {
            next(error);
        }
    }

    static async getUserById(req: Request, res: Response, next: NextFunction) {
        try {
            const id = req.params.id as string;
            const user = await (prisma as any).user.findUnique({
                where: { id },
                select: {
                    id: true,
                    email: true,
                    fullName: true,
                    role: true,
                    createdAt: true,
                    emailVerified: true,
                    profile: {
                        select: {
                            preferredName: true,
                            mobile: true,
                            mailingAddress: true,
                            points: true,
                            bio: true,
                        }
                    },
                    subscriptions: {
                        include: { plan: true },
                        orderBy: { startDate: 'desc' },
                        take: 1,
                    }
                }
            });
            if (!user) return res.status(404).json({ message: 'User not found' });
            res.json(user);
        } catch (error) {
            next(error);
        }
    }

    static async updateUser(req: Request, res: Response, next: NextFunction) {
        try {
            const id = req.params.id as string;
            const { fullName, email, role, preferredName, mobile, mailingAddress, planId } = req.body;

            // Update user fields
            const updateData: any = {};
            if (fullName !== undefined) updateData.fullName = fullName;
            if (email !== undefined) updateData.email = email;
            if (role !== undefined) updateData.role = role;

            if (Object.keys(updateData).length > 0) {
                await prisma.user.update({ where: { id }, data: updateData });
            }

            // Update profile fields (upsert in case profile doesn't exist)
            const profileData: any = {};
            if (preferredName !== undefined) profileData.preferredName = preferredName;
            if (mobile !== undefined) profileData.mobile = mobile;
            if (mailingAddress !== undefined) profileData.mailingAddress = mailingAddress;

            if (Object.keys(profileData).length > 0) {
                await (prisma as any).profile.upsert({
                    where: { userId: id },
                    update: profileData,
                    create: { userId: id, ...profileData },
                });
            }

            // Handle subscription tier change
            // planId === "" means "set to free" (deactivate all), planId is a valid UUID means "set to paid"
            if ('planId' in req.body) {
                if (!planId) {
                    // Downgrade to free: deactivate all active subscriptions, set endDate to past
                    const yesterday = new Date();
                    yesterday.setDate(yesterday.getDate() - 1);
                    await (prisma as any).userSubscription.updateMany({
                        where: { userId: id },
                        data: { isActive: false, endDate: yesterday },
                    });
                } else {
                    const plan = await prisma.subscriptionPlan.findUnique({ where: { id: planId } });
                    if (plan) {
                        const endDate = new Date();
                        endDate.setDate(endDate.getDate() + plan.durationDays);

                        // Deactivate old subscriptions and create new one
                        await (prisma as any).userSubscription.updateMany({
                            where: { userId: id, isActive: true },
                            data: { isActive: false },
                        });
                        await prisma.userSubscription.create({
                            data: { userId: id, planId, endDate, isActive: true, startDate: new Date() }
                        });
                    }
                }
            }

            const updatedUser = await (prisma as any).user.findUnique({
                where: { id },
                select: {
                    id: true, email: true, fullName: true, role: true, createdAt: true,
                    profile: { select: { preferredName: true, mobile: true, mailingAddress: true } },
                    subscriptions: { include: { plan: true }, orderBy: { startDate: 'desc' }, take: 1 }
                }
            });

            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'UPDATE_USER',
                targetType: 'User',
                targetId: id as string,
                payload: req.body
            });

            res.json(updatedUser);
        } catch (error) {
            next(error);
        }
    }

    static async getReports(req: Request, res: Response, next: NextFunction) {
        try {
            const page = parseInt(req.query.page as string) || 1;
            const limit = parseInt(req.query.limit as string) || 15;
            const skip = (page - 1) * limit;

            const [reports, total] = await Promise.all([
                prisma.scamReport.findMany({
                    where: { deletedAt: null },
                    include: {
                        user: {
                            select: {
                                fullName: true,
                                email: true,
                            }
                        }
                    },
                    orderBy: { createdAt: 'desc' },
                    skip,
                    take: limit,
                }),
                prisma.scamReport.count({ where: { deletedAt: null } })
            ]);

            res.json({
                data: reports,
                meta: {
                    total,
                    page,
                    limit,
                    totalPages: Math.ceil(total / limit)
                }
            });
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

            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'UPDATE_REPORT_STATUS',
                targetType: 'ScamReport',
                targetId: id as string,
                payload: { status }
            });

            res.json(updatedReport);
        } catch (error) {
            next(error);
        }
    }

    static async deleteReport(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;

            await prisma.scamReport.update({
                where: { id: id as string },
                data: { deletedAt: new Date() },
            });

            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'DELETE_REPORT',
                targetType: 'ScamReport',
                targetId: id as string
            });

            res.json({ message: 'Report soft-deleted successfully' });
        } catch (error) {
            next(error);
        }
    }

    static async getSubscriptionPlans(req: Request, res: Response, next: NextFunction) {
        try {
            const plans = await prisma.subscriptionPlan.findMany();
            res.json(plans);
        } catch (error) {
            next(error);
        }
    }

    static async createSubscriptionPlan(req: Request, res: Response, next: NextFunction) {
        try {
            const { name, price, features, durationDays } = req.body;
            const plan = await prisma.subscriptionPlan.create({
                data: { name, price, features, durationDays },
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'CREATE_SUBSCRIPTION_PLAN',
                targetType: 'SubscriptionPlan',
                targetId: plan.id,
                payload: req.body
            });

            res.status(201).json(plan);
        } catch (error) {
            next(error);
        }
    }

    static async updateSubscriptionPlan(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            const { name, price, features, durationDays } = req.body;
            const updatedPlan = await prisma.subscriptionPlan.update({
                where: { id: id as string },
                data: { name, price, features, durationDays },
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'UPDATE_SUBSCRIPTION_PLAN',
                targetType: 'SubscriptionPlan',
                targetId: id as string,
                payload: req.body
            });

            res.json(updatedPlan);
        } catch (error) {
            next(error);
        }
    }

    static async deleteSubscriptionPlan(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;

            // Check if plan is being used by any subscriptions before deleting
            const activeSubscriptions = await prisma.userSubscription.count({
                where: { planId: id as string }
            });

            if (activeSubscriptions > 0) {
                res.status(400).json({ message: 'Cannot delete plan with existing subscriptions' });
                return;
            }

            await prisma.subscriptionPlan.delete({
                where: { id: id as string },
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'DELETE_SUBSCRIPTION_PLAN',
                targetType: 'SubscriptionPlan',
                targetId: id as string
            });

            res.json({ message: 'Plan deleted successfully' });
        } catch (error) {
            next(error);
        }
    }

    static async getBadges(req: Request, res: Response, next: NextFunction) {
        try {
            const badges = await prisma.badgeDefinition.findMany();
            res.json(badges);
        } catch (error) {
            next(error);
        }
    }

    static async createBadge(req: Request, res: Response, next: NextFunction) {
        try {
            const { key, name, description, icon, tier, trigger, threshold } = req.body;
            const badge = await prisma.badgeDefinition.create({
                data: { key, name, description, icon, tier, trigger, threshold: threshold ? Number(threshold) : null },
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'CREATE_BADGE',
                targetType: 'BadgeDefinition',
                targetId: badge.id,
                payload: req.body
            });

            res.status(201).json(badge);
        } catch (error) {
            next(error);
        }
    }

    static async updateBadge(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            const { key, name, description, icon, tier, trigger, threshold } = req.body;
            const updatedBadge = await prisma.badgeDefinition.update({
                where: { id: id as string },
                data: { key, name, description, icon, tier, trigger, threshold: threshold ? Number(threshold) : null },
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'UPDATE_BADGE',
                targetType: 'BadgeDefinition',
                targetId: id as string,
                payload: req.body
            });

            res.json(updatedBadge);
        } catch (error) {
            next(error);
        }
    }

    static async deleteBadge(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            await prisma.badgeDefinition.delete({
                where: { id: id as string },
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'DELETE_BADGE',
                targetType: 'BadgeDefinition',
                targetId: id as string
            });

            res.json({ message: 'Badge deleted successfully' });
        } catch (error) {
            next(error);
        }
    }

    static async getRewards(req: Request, res: Response, next: NextFunction) {
        try {
            const rewards = await prisma.reward.findMany({
                orderBy: { createdAt: 'desc' }
            });
            res.json(rewards);
        } catch (error) {
            next(error);
        }
    }

    static async createReward(req: Request, res: Response, next: NextFunction) {
        try {
            const { name, description, pointsCost, type, metadata, active } = req.body;
            const reward = await prisma.reward.create({
                data: { name, description, pointsCost: Number(pointsCost), type, metadata: metadata || {}, active },
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'CREATE_REWARD',
                targetType: 'Reward',
                targetId: reward.id,
                payload: req.body
            });

            res.status(201).json(reward);
        } catch (error) {
            next(error);
        }
    }

    static async updateReward(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            const { name, description, pointsCost, type, metadata, active } = req.body;
            const updatedReward = await prisma.reward.update({
                where: { id: id as string },
                data: { name, description, pointsCost: Number(pointsCost), type, metadata: metadata || {}, active },
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'UPDATE_REWARD',
                targetType: 'Reward',
                targetId: id as string,
                payload: req.body
            });

            res.json(updatedReward);
        } catch (error) {
            next(error);
        }
    }

    static async deleteReward(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            await prisma.reward.delete({
                where: { id: id as string },
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'DELETE_REWARD',
                targetType: 'Reward',
                targetId: id as string
            });

            res.json({ message: 'Reward deleted successfully' });
        } catch (error) {
            next(error);
        }
    }

    static async getRedemptions(req: Request, res: Response, next: NextFunction) {
        try {
            const redemptions = await prisma.redemption.findMany({
                include: {
                    user: { select: { fullName: true, email: true } },
                    reward: { select: { name: true, type: true } }
                },
                orderBy: { createdAt: 'desc' }
            });
            res.json(redemptions);
        } catch (error) {
            next(error);
        }
    }

    static async updateRedemptionStatus(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            const { status } = req.body;

            const updatedRedemption = await prisma.redemption.update({
                where: { id: id as string },
                data: { status },
                include: {
                    user: { select: { fullName: true, email: true } },
                    reward: { select: { name: true, type: true } }
                }
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'UPDATE_REDEMPTION_STATUS',
                targetType: 'Redemption',
                targetId: id as string,
                payload: { status }
            });

            res.json(updatedRedemption);
        } catch (error) {
            next(error);
        }
    }

    static async getBroadcasts(req: Request, res: Response, next: NextFunction) {
        try {
            // Group by message to represent unique broadcasts
            const broadcasts = await prisma.alert.groupBy({
                by: ['message', 'title', 'type', 'createdAt'],
                where: { type: 'BROADCAST' },
                _count: { userId: true },
                orderBy: { createdAt: 'desc' }
            });
            // Format to a more UI friendly shape
            const formatted = broadcasts.map((b: any) => ({
                id: Buffer.from(b.message + b.createdAt.getTime()).toString('base64'), // mock ID for UI
                title: b.title,
                message: b.message,
                type: b.type,
                createdAt: b.createdAt,
                recipientCount: b._count.userId
            }));
            res.json(formatted);
        } catch (error) {
            next(error);
        }
    }

    static async createBroadcast(req: Request, res: Response, next: NextFunction) {
        try {
            const { title, message } = req.body;

            // Get all user IDs to broadcast to
            const users = await prisma.user.findMany({ select: { id: true } });

            if (users.length === 0) {
                res.status(400).json({ message: 'No users found to broadcast to.' });
                return;
            }

            const alertData = users.map(user => ({
                userId: user.id,
                type: 'BROADCAST',
                title: title,
                message: message,
            }));

            const result = await prisma.alert.createMany({
                data: alertData as any,
                skipDuplicates: true,
            });

            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'CREATE_BROADCAST',
                targetType: 'Alert',
                payload: { title, message, recipients: result.count }
            });

            res.status(201).json({
                message: 'Broadcast sent successfully',
                recipients: result.count
            });
        } catch (error) {
            next(error);
        }
    }

    static async updateBroadcast(req: Request, res: Response, next: NextFunction) {
        try {
            res.status(400).json({ message: 'Updates to sent broadcasts are not supported.' });
        } catch (error) {
            next(error);
        }
    }

    static async deleteBroadcast(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            res.status(400).json({ message: 'Deletions of sent broadcasts are not supported.' });
        } catch (error) {
            next(error);
        }
    }

    static async getTransactions(req: Request, res: Response, next: NextFunction) {
        try {
            // Aggregate suspicious transactions for review
            const transactions = await prisma.transactionJournal.findMany({
                where: {
                    OR: [
                        { status: 'SUSPICIOUS' },
                        { riskScore: { gte: 50 } }
                    ]
                },
                include: { user: { select: { fullName: true, email: true } } },
                orderBy: { createdAt: 'desc' },
                take: 100 // Limit for performance
            });
            res.json(transactions);
        } catch (error) {
            next(error);
        }
    }

    static async getFraudLabels(req: Request, res: Response, next: NextFunction) {
        try {
            const labels = await prisma.fraudLabel.findMany({
                orderBy: { createdAt: 'desc' }
            });
            res.json(labels);
        } catch (error) {
            next(error);
        }
    }

    static async createFraudLabel(req: Request, res: Response, next: NextFunction) {
        try {
            const { txId, label } = req.body;
            // Assumes admin is labeled by "SYSTEM" or a specific admin ID
            const fraudLabel = await prisma.fraudLabel.create({
                data: {
                    txId,
                    label,
                    labeledBy: (req as any).user?.id || 'SYSTEM_ADMIN'
                }
            });

            // Optionally, update the associated transaction journal to SCAMMED
            if (txId) {
                await prisma.transactionJournal.updateMany({
                    where: { id: txId },
                    data: { status: 'SCAMMED' }
                });
            }

            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'CREATE_FRAUD_LABEL',
                targetType: 'FraudLabel',
                targetId: fraudLabel.id,
                payload: { txId, label }
            });

            res.status(201).json(fraudLabel);
        } catch (error) {
            next(error);
        }
    }

    static async deleteFraudLabel(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            await prisma.fraudLabel.delete({
                where: { id: id as string }
            });
            const adminId = (req.user as any).id;
            await AuditService.logAction({
                adminId,
                action: 'DELETE_FRAUD_LABEL',
                targetType: 'FraudLabel',
                targetId: id as string
            });

            res.json({ message: 'Fraud label deleted successfully' });
        } catch (error) {
            next(error);
        }
    }

    static async getStats(req: Request, res: Response, next: NextFunction) {
        try {
            const [userCount, reportCount, pendingReports] = await Promise.all([
                prisma.user.count(),
                prisma.scamReport.count({ where: { deletedAt: null } }),
                prisma.scamReport.count({ where: { status: 'PENDING', deletedAt: null } }),
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
