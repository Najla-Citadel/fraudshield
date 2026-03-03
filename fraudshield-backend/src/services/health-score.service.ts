import { prisma } from '../config/database';

export class HealthScoreService {
    static async calculateScore(userId: string): Promise<{
        score: number,
        breakdown: {
            verification: number,
            subscription: number,
            profile: number,
            reputation: number,
            activity: number,
            alerts: number
        }
    }> {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                profile: true,
                subscriptions: {
                    where: { isActive: true },
                    take: 1
                },
                reports: {
                    take: 10
                },
                alertSubscription: true
            }
        });

        if (!user) {
            throw new Error('User not found');
        }

        // 1. Email Verification (+20)
        const verificationScore = user.emailVerified ? 20 : 0;

        // 2. Active Subscription (+30)
        const subscriptionScore = user.subscriptions.length > 0 ? 30 : 0;

        // 3. Profile Completeness (+15)
        let profilePoints = 0;
        if (user.fullName) profilePoints += 3.75;
        if (user.profile?.bio) profilePoints += 3.75;
        if (user.profile?.avatar) profilePoints += 3.75;
        if (user.profile?.mobile) profilePoints += 3.75;
        const profileScore = Math.round(profilePoints);

        // 4. Reputation (+15)
        // Scaled: reputation 50+ = 15 points
        const reputation = user.profile?.reputation || 0;
        const reputationScore = Math.min(15, Math.floor((reputation / 50) * 15));

        // 5. Activity (+10)
        // Scaled: 10 reports = 10 points
        const activityScore = Math.min(10, user.reports.length);

        // 6. Alert Subscription (+10)
        const alertScore = user.alertSubscription?.isActive ? 10 : 0;

        const totalScore = verificationScore + subscriptionScore + profileScore + reputationScore + activityScore + alertScore;

        return {
            score: Math.min(100, totalScore),
            breakdown: {
                verification: verificationScore,
                subscription: subscriptionScore,
                profile: profileScore,
                reputation: reputationScore,
                activity: activityScore,
                alerts: alertScore
            }
        };
    }
}
