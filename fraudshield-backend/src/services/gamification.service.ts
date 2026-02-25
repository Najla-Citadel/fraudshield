import { prisma } from '../config/database';
import { BadgeService } from './badge.service';

export enum Tier {
    BRONZE = 'BRONZE',
    SILVER = 'SILVER',
    GOLD = 'GOLD',
    DIAMOND = 'DIAMOND'
}

export const TIER_THRESHOLDS = {
    [Tier.BRONZE]: 0,
    [Tier.SILVER]: 1000,
    [Tier.GOLD]: 5000,
    [Tier.DIAMOND]: 10000
};

export class GamificationService {
    /**
     * Awards points to a user and updates their current and total points.
     * Also checks for tier upgrades and badges.
     */
    static async awardPoints(userId: string, amount: number, description: string): Promise<{
        newBalance: number;
        totalPoints: number;
        currentTier: Tier;
        newBadges: string[];
    }> {
        try {
            // 1. Update Profile (points and totalPoints)
            const profile = await (prisma as any).profile.update({
                where: { userId },
                data: {
                    points: { increment: amount },
                    totalPoints: { increment: amount }
                }
            });

            // 2. Log Transaction
            await (prisma as any).pointsTransaction.create({
                data: {
                    userId,
                    amount,
                    description
                }
            });

            // 3. Calculate Tier
            const currentTier = this.calculateTier(profile.totalPoints);

            // 4. Evaluate Badges (existing logic)
            const newBadges = await BadgeService.evaluateBadges(userId);

            return {
                newBalance: profile.points,
                totalPoints: profile.totalPoints,
                currentTier,
                newBadges
            };
        } catch (error) {
            console.error('Error awarding points:', error);
            throw error;
        }
    }

    /**
     * Determines the tier based on total points earned.
     */
    static calculateTier(totalPoints: number): Tier {
        if (totalPoints >= TIER_THRESHOLDS[Tier.DIAMOND]) return Tier.DIAMOND;
        if (totalPoints >= TIER_THRESHOLDS[Tier.GOLD]) return Tier.GOLD;
        if (totalPoints >= TIER_THRESHOLDS[Tier.SILVER]) return Tier.SILVER;
        return Tier.BRONZE;
    }

    /**
     * Gets the next tier and points needed.
     */
    static getTierProgress(totalPoints: number) {
        const currentTier = this.calculateTier(totalPoints);
        let nextTier: Tier | null = null;
        let pointsNeeded = 0;

        if (currentTier === Tier.BRONZE) {
            nextTier = Tier.SILVER;
            pointsNeeded = TIER_THRESHOLDS[Tier.SILVER] - totalPoints;
        } else if (currentTier === Tier.SILVER) {
            nextTier = Tier.GOLD;
            pointsNeeded = TIER_THRESHOLDS[Tier.GOLD] - totalPoints;
        } else if (currentTier === Tier.GOLD) {
            nextTier = Tier.DIAMOND;
            pointsNeeded = TIER_THRESHOLDS[Tier.DIAMOND] - totalPoints;
        }

        return {
            currentTier,
            nextTier,
            pointsNeeded: Math.max(0, pointsNeeded),
            totalPoints
        };
    }
}
