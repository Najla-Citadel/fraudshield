import { prisma } from '../config/database';

export class BadgeService {
    /**
     * Evaluates a user's stats against available badge definitions.
     * Award any new badges that the user qualifies for.
     */
    static async evaluateBadges(userId: string): Promise<string[]> {
        try {
            // 1. Get user profile and stats
            const profile = await (prisma as any).profile.findUnique({
                where: { userId },
                include: {
                    user: {
                        include: {
                            _count: {
                                select: {
                                    reports: true,
                                }
                            },
                        }
                    }
                }
            });

            if (!profile) return [];

            // Get verification count
            const verificationCount = await (prisma as any).verification.count({
                where: { userId }
            });

            // 2. Get all badge definitions (except those earned by purchase)
            const definitions = await (prisma as any).badgeDefinition.findMany({
                where: {
                    trigger: {
                        not: 'purchase'
                    }
                }
            });

            // 3. Current badges
            let currentBadges: string[] = [];
            if (Array.isArray(profile.badges)) {
                currentBadges = profile.badges as string[];
            } else if (typeof profile.badges === 'string') {
                try {
                    const parsed = JSON.parse(profile.badges);
                    if (Array.isArray(parsed)) currentBadges = parsed;
                } catch (e) {
                    console.error('Error parsing badges:', e);
                }
            }

            const newlyEarned: string[] = [];

            // 4. Check each definition
            for (const def of definitions) {
                if (currentBadges.includes(def.key)) continue;

                let qualifies = false;
                const threshold = def.threshold || 0;

                switch (def.trigger) {
                    case 'reputation':
                        qualifies = (profile.reputation || 0) >= threshold;
                        break;
                    case 'reports':
                        qualifies = (profile.user?._count?.reports || 0) >= threshold;
                        break;
                    case 'verifications':
                        qualifies = verificationCount >= threshold;
                        break;
                    case 'streak':
                        qualifies = (profile.loginStreak || 0) >= threshold;
                        break;
                }

                if (qualifies) {
                    newlyEarned.push(def.key);
                }
            }

            // 5. Update profile if new badges earned
            if (newlyEarned.length > 0) {
                const updatedBadges = [...currentBadges, ...newlyEarned];
                await (prisma as any).profile.update({
                    where: { userId },
                    data: {
                        badges: updatedBadges
                    }
                });

                // Create points transactions for each new badge (optional notification)
                for (const badgeKey of newlyEarned) {
                    await (prisma as any).pointsTransaction.create({
                        data: {
                            userId,
                            amount: 0, // Badges don't necessarily give points, but we log the event
                            description: `Earned Badge: ${badgeKey}`,
                        }
                    });
                }
            }

            return newlyEarned;
        } catch (error) {
            console.error('Error evaluating badges:', error);
            return [];
        }
    }

    /**
     * Returns detailed badge information (definition + earned status)
     */
    static async getBadgeLibrary(userId: string) {
        const [definitions, profile] = await Promise.all([
            (prisma as any).badgeDefinition.findMany({
                orderBy: { tier: 'asc' }
            }),
            (prisma as any).profile.findUnique({
                where: { userId },
                select: { badges: true }
            })
        ]);

        let earnedKeys: string[] = [];
        if (profile) {
            if (Array.isArray(profile.badges)) {
                earnedKeys = profile.badges as string[];
            } else if (typeof profile.badges === 'string') {
                try {
                    const parsed = JSON.parse(profile.badges);
                    if (Array.isArray(parsed)) earnedKeys = parsed;
                } catch (e) { }
            }
        }

        return definitions.map((def: any) => ({
            ...def,
            isEarned: earnedKeys.includes(def.key)
        }));
    }
}
