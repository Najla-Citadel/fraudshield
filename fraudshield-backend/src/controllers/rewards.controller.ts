import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { BadgeService } from '../services/badge.service';


export class RewardsController {
    // Get all available rewards
    static async getRewards(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { limit = '20', offset = '0' } = req.query;
            const limitNum = parseInt(limit as string, 10);
            const offsetNum = parseInt(offset as string, 10);

            const profile = await (prisma as any).profile.findUnique({
                where: { userId },
                select: { totalPoints: true, points: true }
            });

            const userTotalPoints = profile?.totalPoints || 0;
            const currentTier = RewardsController.calculateTier(userTotalPoints);
            const discount = RewardsController.getTierDiscount(currentTier);

            const [rewards, total] = await Promise.all([
                (prisma as any).reward.findMany({
                    where: { active: true },
                    orderBy: { pointsCost: 'asc' },
                    take: limitNum,
                    skip: offsetNum,
                }),
                (prisma as any).reward.count({ where: { active: true } }),
            ]);

            const tierOrder = ['BRONZE', 'SILVER', 'GOLD', 'DIAMOND'];
            const userTierIndex = tierOrder.indexOf(currentTier);

            const results = rewards.map((r: any) => {
                const requiredTierIndex = tierOrder.indexOf(r.minTier || 'BRONZE');
                const isLocked = requiredTierIndex > userTierIndex;
                const discountedCost = Math.round(r.pointsCost * (1 - discount));

                return {
                    ...r,
                    originalCost: r.pointsCost,
                    pointsCost: discountedCost,
                    isLocked,
                    requiredTier: r.minTier
                };
            });

            res.json({
                results,
                total,
                hasMore: offsetNum + limitNum < total,
                userTier: currentTier,
                userDiscount: discount,
                userBalance: profile?.points || 0
            });
        } catch (error) {
            next(error);
        }
    }

    // Redeem points for a reward
    static async redeemReward(req: Request, res: Response, next: NextFunction) {
        try {
            const { rewardId } = req.body;
            const userId = (req.user as any).id;

            // 1. Get the reward
            const reward = await (prisma as any).reward.findUnique({
                where: { id: rewardId },
            });

            if (!reward || !reward.active) {
                return res.status(404).json({ error: 'Reward not found or inactive' });
            }

            // 2. Get user's current points
            const profile = await (prisma as any).profile.findUnique({
                where: { userId },
            });

            if (!profile) {
                return res.status(404).json({ error: 'User profile not found' });
            }

            // 3. Calculate discounted cost
            const currentTier = RewardsController.calculateTier(profile.totalPoints || 0);
            const discount = RewardsController.getTierDiscount(currentTier);
            const discountedCost = Math.round(reward.pointsCost * (1 - discount));

            // 4. Check Tier Lock
            const tierOrder = ['BRONZE', 'SILVER', 'GOLD', 'DIAMOND'];
            const userTierIndex = tierOrder.indexOf(currentTier);
            const requiredTierIndex = tierOrder.indexOf(reward.minTier || 'BRONZE');

            if (requiredTierIndex > userTierIndex) {
                return res.status(403).json({
                    error: 'Tier locked',
                    requiredTier: reward.minTier,
                    currentTier
                });
            }

            // 5. Check if user has enough points
            if (profile.points < discountedCost) {
                return res.status(400).json({
                    error: 'Insufficient points',
                    required: discountedCost,
                    current: profile.points,
                });
            }

            // 6. Create redemption and deduct points in a transaction
            const result = await (prisma as any).$transaction(async (tx: any) => {
                // Deduct points from profile
                await tx.profile.update({
                    where: { userId },
                    data: { points: { decrement: discountedCost } },
                });

                // Create negative points transaction
                await tx.pointsTransaction.create({
                    data: {
                        userId,
                        amount: -discountedCost,
                        description: `Redeemed: ${reward.name} (incl. ${Math.round(discount * 100)}% tier discount)`,
                    },
                });

                // Create redemption record
                const redemption = await tx.redemption.create({
                    data: {
                        userId,
                        rewardId,
                        pointsCost: discountedCost,
                        status: 'completed',
                    },
                    include: {
                        reward: true,
                    },
                });

                // 7. Apply reward based on type
                if (reward.type === 'subscription') {
                    const metadata = reward.metadata as any;
                    const durationDays = metadata.durationDays || 30;

                    let plan = await tx.subscriptionPlan.findFirst({
                        where: { name: reward.name },
                    });

                    if (!plan) {
                        plan = await tx.subscriptionPlan.create({
                            data: {
                                name: reward.name,
                                price: 0,
                                features: metadata.features || [],
                                durationDays,
                            },
                        });
                    }

                    const existingSubscription = await tx.userSubscription.findFirst({
                        where: { userId, isActive: true },
                    });

                    if (existingSubscription) {
                        const newEndDate = new Date(existingSubscription.endDate);
                        newEndDate.setDate(newEndDate.getDate() + durationDays);
                        await tx.userSubscription.update({
                            where: { id: existingSubscription.id },
                            data: { endDate: newEndDate },
                        });
                    } else {
                        const endDate = new Date();
                        endDate.setDate(endDate.getDate() + durationDays);
                        await tx.userSubscription.create({
                            data: {
                                userId,
                                planId: plan.id,
                                startDate: new Date(),
                                endDate,
                                isActive: true,
                            },
                        });
                    }
                } else if (reward.type === 'badge') {
                    const metadata = reward.metadata as any;
                    const badgeName = metadata.badgeName || reward.name;
                    let currentBadges: string[] = [];
                    if (Array.isArray(profile.badges)) {
                        currentBadges = profile.badges as string[];
                    } else if (typeof profile.badges === 'string') {
                        try {
                            const parsed = JSON.parse(profile.badges);
                            if (Array.isArray(parsed)) {
                                currentBadges = parsed;
                            }
                        } catch (e) { }
                    }

                    if (!currentBadges.includes(badgeName)) {
                        await tx.profile.update({
                            where: { userId },
                            data: { badges: [...currentBadges, badgeName] },
                        });
                    }
                }

                return redemption;
            });

            res.status(201).json(result);
        } catch (error) {
            next(error);
        }
    }

    // Get user's redemption history
    static async getMyRedemptions(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { limit = '20', offset = '0' } = req.query;
            const limitNum = parseInt(limit as string, 10);
            const offsetNum = parseInt(offset as string, 10);

            const [redemptions, total] = await Promise.all([
                (prisma as any).redemption.findMany({
                    where: { userId },
                    include: { reward: true },
                    orderBy: { createdAt: 'desc' },
                    take: limitNum,
                    skip: offsetNum,
                }),
                (prisma as any).redemption.count({ where: { userId } }),
            ]);

            res.json({
                results: redemptions,
                total,
                hasMore: offsetNum + limitNum < total,
            });
        } catch (error) {
            next(error);
        }
    }

    // Seed initial rewards
    static async seedRewards(req: Request, res: Response, next: NextFunction) {
        try {
            const rewards = [
                {
                    name: '1 Month Premium',
                    description: 'Unlock all premium features for 30 days',
                    pointsCost: 500,
                    type: 'subscription',
                    minTier: 'BRONZE',
                    isFeatured: true,
                    metadata: {
                        durationDays: 30,
                        features: ['Unlimited scans', 'Priority support'],
                    },
                },
                {
                    name: '3 Months Premium',
                    description: 'Unlock all premium features for 90 days',
                    pointsCost: 1200,
                    type: 'subscription',
                    minTier: 'SILVER',
                    isFeatured: true,
                    metadata: {
                        durationDays: 90,
                        features: ['Unlimited scans', 'Priority support'],
                    },
                },
                {
                    name: 'Elite Shield Access',
                    description: 'Exclusive Gold-tier security features',
                    pointsCost: 3000,
                    type: 'subscription',
                    minTier: 'GOLD',
                    isFeatured: true,
                    metadata: {
                        durationDays: 180,
                        features: ['Advanced AI Risk Score', 'Custom Alert Rules'],
                    },
                },
                {
                    name: 'Diamond Guardian Badge',
                    description: 'The ultimate mark of a scam fighter',
                    pointsCost: 8000,
                    type: 'badge',
                    minTier: 'DIAMOND',
                    metadata: {
                        badgeName: 'Diamond Guardian',
                        icon: '💎',
                    },
                }
            ];

            const createdRewards = await (prisma as any).reward.createMany({
                data: rewards,
                skipDuplicates: true,
            });

            res.json({
                message: 'Seeding successful',
                rewardsCount: createdRewards.count,
            });
        } catch (error) {
            next(error);
        }
    }

    static async claimDailyReward(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const now = new Date();
            const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

            const profile = await (prisma as any).profile.findUnique({ where: { userId } });
            if (!profile) return res.status(404).json({ error: 'Profile not found' });

            let streak = profile.loginStreak || 0;
            let lastLogin = profile.lastLoginDate ? new Date(profile.lastLoginDate) : null;
            if (lastLogin) {
                lastLogin = new Date(lastLogin.getFullYear(), lastLogin.getMonth(), lastLogin.getDate());
            }

            if (lastLogin && lastLogin.getTime() === today.getTime()) {
                return res.json({ claimed: false, message: 'Already claimed today' });
            }

            if (lastLogin && (today.getTime() - lastLogin.getTime() === 86400000)) {
                streak += 1;
            } else {
                streak = 1;
            }

            const pointsAwarded = RewardsController.calculateReward(streak);

            await (prisma as any).$transaction([
                (prisma as any).profile.update({
                    where: { userId },
                    data: {
                        lastLoginDate: now,
                        loginStreak: streak,
                        points: { increment: pointsAwarded },
                        totalPoints: { increment: pointsAwarded }
                    },
                }),
                (prisma as any).pointsTransaction.create({
                    data: {
                        userId,
                        amount: pointsAwarded,
                        description: `Daily Login Reward (Day ${streak})`,
                    },
                }),
            ]);

            const newBadges = await BadgeService.evaluateBadges(userId);
            res.json({ claimed: true, points: pointsAwarded, streak, newBadges });
        } catch (error) {
            next(error);
        }
    }

    private static calculateReward(streak: number): number {
        const base = 10;
        return base + Math.min(streak * 5, 50);
    }

    private static calculateTier(totalPoints: number): string {
        if (totalPoints >= 10000) return 'DIAMOND';
        if (totalPoints >= 5000) return 'GOLD';
        if (totalPoints >= 1000) return 'SILVER';
        return 'BRONZE';
    }

    private static getTierDiscount(tier: string): number {
        switch (tier) {
            case 'DIAMOND': return 0.20;
            case 'GOLD': return 0.10;
            default: return 0;
        }
    }
}
