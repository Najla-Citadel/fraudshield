import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { BadgeService } from '../services/badge.service';


export class RewardsController {
    // Get all available rewards
    static async getRewards(req: Request, res: Response, next: NextFunction) {
        try {
            const rewards = await (prisma as any).reward.findMany({
                where: { active: true },
                orderBy: { pointsCost: 'asc' },
            });

            res.json(rewards);
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

            // 3. Check if user has enough points
            if (profile.points < reward.pointsCost) {
                return res.status(400).json({
                    error: 'Insufficient points',
                    required: reward.pointsCost,
                    current: profile.points,
                });
            }

            // 4. Create redemption and deduct points in a transaction
            const result = await (prisma as any).$transaction(async (tx: any) => {
                // Deduct points from profile
                await tx.profile.update({
                    where: { userId },
                    data: { points: { decrement: reward.pointsCost } },
                });

                // Create negative points transaction
                await tx.pointsTransaction.create({
                    data: {
                        userId,
                        amount: -reward.pointsCost,
                        description: `Redeemed: ${reward.name}`,
                    },
                });

                // Create redemption record
                const redemption = await tx.redemption.create({
                    data: {
                        userId,
                        rewardId,
                        pointsCost: reward.pointsCost,
                        status: 'completed',
                    },
                    include: {
                        reward: true,
                    },
                });

                // 5. Apply reward based on type
                if (reward.type === 'subscription') {
                    const metadata = reward.metadata as any;
                    const durationDays = metadata.durationDays || 30;

                    // Find or create a subscription plan
                    let plan = await tx.subscriptionPlan.findFirst({
                        where: { name: reward.name },
                    });

                    if (!plan) {
                        plan = await tx.subscriptionPlan.create({
                            data: {
                                name: reward.name,
                                price: 0, // Free via points
                                features: metadata.features || [],
                                durationDays,
                            },
                        });
                    }

                    // Create or extend subscription
                    const existingSubscription = await tx.userSubscription.findFirst({
                        where: {
                            userId,
                            isActive: true,
                        },
                    });

                    if (existingSubscription) {
                        // Extend existing subscription
                        const newEndDate = new Date(existingSubscription.endDate);
                        newEndDate.setDate(newEndDate.getDate() + durationDays);

                        await tx.userSubscription.update({
                            where: { id: existingSubscription.id },
                            data: { endDate: newEndDate },
                        });
                    } else {
                        // Create new subscription
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
                    // Add badge to user profile
                    const metadata = reward.metadata as any;
                    const badgeName = metadata.badgeName || reward.name;

                    // Safely handle badges which might be stringified Json in DB
                    let currentBadges: string[] = [];
                    if (Array.isArray(profile.badges)) {
                        currentBadges = profile.badges as string[];
                    } else if (typeof profile.badges === 'string') {
                        try {
                            const parsed = JSON.parse(profile.badges);
                            if (Array.isArray(parsed)) {
                                currentBadges = parsed;
                            }
                        } catch (e) {
                            console.error('Error parsing badges from DB:', e);
                        }
                    }

                    if (!currentBadges.includes(badgeName)) {
                        await tx.profile.update({
                            where: { userId },
                            data: {
                                badges: [...currentBadges, badgeName],
                            },
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

            const redemptions = await (prisma as any).redemption.findMany({
                where: { userId },
                include: {
                    reward: true,
                },
                orderBy: { createdAt: 'desc' },
            });

            res.json(redemptions);
        } catch (error) {
            next(error);
        }
    }

    // Seed initial rewards (admin only or run once)
    static async seedRewards(req: Request, res: Response, next: NextFunction) {
        try {
            const rewards = [
                {
                    name: '1 Month Premium',
                    description: 'Unlock all premium features for 30 days',
                    pointsCost: 500,
                    type: 'subscription',
                    metadata: {
                        durationDays: 30,
                        features: ['Unlimited scans', 'Priority support', 'Advanced analytics'],
                    },
                },
                {
                    name: '3 Months Premium',
                    description: 'Unlock all premium features for 90 days',
                    pointsCost: 1200,
                    type: 'subscription',
                    metadata: {
                        durationDays: 90,
                        features: ['Unlimited scans', 'Priority support', 'Advanced analytics'],
                    },
                },
                {
                    name: '1 Year Premium',
                    description: 'Unlock all premium features for 365 days',
                    pointsCost: 4000,
                    type: 'subscription',
                    metadata: {
                        durationDays: 365,
                        features: ['Unlimited scans', 'Priority support', 'Advanced analytics'],
                    },
                },
                {
                    name: 'Scam Hunter Badge',
                    description: 'Show off your scam-fighting prowess',
                    pointsCost: 300,
                    type: 'badge',
                    metadata: {
                        badgeName: 'Scam Hunter',
                        icon: '🎯',
                    },
                },
                {
                    name: 'Guardian Badge',
                    description: 'Protect the community with pride',
                    pointsCost: 200,
                    type: 'badge',
                    metadata: {
                        badgeName: 'Guardian',
                        icon: '🛡️',
                    },
                },
            ];

            const createdRewards = await (prisma as any).reward.createMany({
                data: rewards,
                skipDuplicates: true,
            });

            const badges = [
                {
                    key: 'first_report',
                    name: 'First Responder',
                    description: 'Submitted your first public scam report',
                    icon: '🎯',
                    tier: 'bronze',
                    trigger: 'reports',
                    threshold: 1
                },
                {
                    key: 'community_guardian',
                    name: 'Community Guardian',
                    description: 'Submitted 10 public scam reports',
                    icon: '🛡️',
                    tier: 'silver',
                    trigger: 'reports',
                    threshold: 10
                },
                {
                    key: 'senior_sentinel',
                    name: 'Senior Sentinel',
                    description: 'Submitted 50 public scam reports',
                    icon: '🥇',
                    tier: 'gold',
                    trigger: 'reports',
                    threshold: 50
                },
                {
                    key: 'first_verify',
                    name: 'Truth Seeker',
                    description: 'Verified your first scam report',
                    icon: '🔍',
                    tier: 'bronze',
                    trigger: 'verifications',
                    threshold: 1
                },
                {
                    key: 'elite_verifier',
                    name: 'Elite Verifier',
                    description: 'Verified 25 scam reports',
                    icon: '⚖️',
                    tier: 'silver',
                    trigger: 'verifications',
                    threshold: 25
                },
                {
                    key: 'elite_sentinel',
                    name: 'Elite Sentinel',
                    description: 'Reached 50 reputation points',
                    icon: '💎',
                    tier: 'gold',
                    trigger: 'reputation',
                    threshold: 50
                },
                {
                    key: 'streak_master',
                    name: 'Streak Master',
                    description: 'Logged in for 7 consecutive days',
                    icon: '🔥',
                    tier: 'silver',
                    trigger: 'streak',
                    threshold: 7
                }
            ];

            const createdBadges = await (prisma as any).badgeDefinition.createMany({
                data: badges,
                skipDuplicates: true,
            });

            res.json({
                message: 'Seeding successful',
                rewardsCount: createdRewards.count,
                badgesCount: createdBadges.count
            });

        } catch (error) {
            next(error);
        }
    }

    // Claim daily login reward
    static async claimDailyReward(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const now = new Date();
            const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()); // Start of today

            const profile = await (prisma as any).profile.findUnique({
                where: { userId },
            });

            if (!profile) {
                return res.status(404).json({ error: 'Profile not found' });
            }

            let streak = profile.loginStreak || 0;
            let lastLogin = profile.lastLoginDate ? new Date(profile.lastLoginDate) : null;
            let pointsAwarded = 0;
            let message = '';

            // Normalize lastLogin to start of its day
            if (lastLogin) {
                lastLogin = new Date(lastLogin.getFullYear(), lastLogin.getMonth(), lastLogin.getDate());
            }

            if (lastLogin && lastLogin.getTime() === today.getTime()) {
                // Already claimed today
                return res.json({
                    claimed: false,
                    message: 'Already claimed today',
                    streak,
                    nextReward: RewardsController.calculateReward(streak + 1),
                });
            }

            if (lastLogin && (today.getTime() - lastLogin.getTime() === 86400000)) {
                // Consecutive day
                streak += 1;
                message = `Daily streak! ${streak} days in a row.`;
            } else {
                // Missed a day or first time
                streak = 1;
                message = 'Daily reward claimed!';
            }

            pointsAwarded = RewardsController.calculateReward(streak);

            // Update profile and add points transaction
            await (prisma as any).$transaction([
                (prisma as any).profile.update({
                    where: { userId },
                    data: {
                        lastLoginDate: now,
                        loginStreak: streak,
                        points: { increment: pointsAwarded },
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

            // Evaluate badges for the user
            const newBadges = await BadgeService.evaluateBadges(userId);

            res.json({
                claimed: true,
                message,
                points: pointsAwarded,
                streak,
                nextReward: RewardsController.calculateReward(streak + 1),
                newBadges,
            });


        } catch (error) {
            next(error);
        }
    }

    private static calculateReward(streak: number): number {
        const base = 10;
        const bonus = Math.min(streak * 5, 50); // Cap bonus at 50
        return base + bonus;
    }
}
