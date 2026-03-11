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
    private static readonly DAILY_CAP = 100;

    /**
     * Awards points to a user and updates their current and total points.
     * Also checks for tier upgrades and badges.
     * Enforces a daily cap of 100 points.
     */
    static async awardPoints(userId: string, amount: number, description: string): Promise<{
        newBalance: number;
        totalPoints: number;
        currentTier: Tier;
        newBadges: string[];
        awardedAmount: number;
    }> {
        try {
            // 1. Fetch current profile to check daily cap
            const currentProfile = await (prisma as any).profile.findUnique({
                where: { userId }
            });

            if (!currentProfile) {
                throw new Error('User profile not found');
            }

            // 2. Check for daily reset
            const now = new Date();
            const lastReset = new Date(currentProfile.lastPointsReset || 0);
            const isDifferentDay = now.getDate() !== lastReset.getDate() || 
                                 now.getMonth() !== lastReset.getMonth() || 
                                 now.getFullYear() !== lastReset.getFullYear();

            let dailyEarned = isDifferentDay ? 0 : currentProfile.dailyPointsEarned;
            let awardedAmount = amount;

            // 3. Enforce Daily Cap
            if (dailyEarned >= this.DAILY_CAP) {
                awardedAmount = 0;
            } else if (dailyEarned + amount > this.DAILY_CAP) {
                awardedAmount = this.DAILY_CAP - dailyEarned;
            }

            let finalDescription = description;
            if (awardedAmount < amount) {
                finalDescription += awardedAmount === 0 
                    ? ' (Capped: Daily limit reached)' 
                    : ` (Partially Capped: Daily limit reached)`;
            }

            // 4. Update Profile
            const profile = await (prisma as any).profile.update({
                where: { userId },
                data: {
                    points: { increment: awardedAmount },
                    totalPoints: { increment: awardedAmount },
                    dailyPointsEarned: isDifferentDay ? awardedAmount : { increment: awardedAmount },
                    lastPointsReset: now
                }
            });

            // 5. Log Transaction (only if points were awarded, or log as 0 if capped?)
            // We'll log even if 0 to show the user the limit was hit in history
            await (prisma as any).pointsTransaction.create({
                data: {
                    userId,
                    amount: awardedAmount,
                    description: finalDescription
                }
            });

            // 6. Calculate Tier
            const currentTier = this.calculateTier(profile.totalPoints);

            // 7. Evaluate Badges
            const newBadges = await BadgeService.evaluateBadges(userId);

            return {
                newBalance: profile.points,
                totalPoints: profile.totalPoints,
                currentTier,
                newBadges,
                awardedAmount
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
