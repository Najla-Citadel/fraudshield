import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';

export class LeaderboardController {
    static async getGlobalLeaderboard(req: Request, res: Response, next: NextFunction) {
        try {
            const topUsers = await prisma.profile.findMany({
                where: {
                    user: {
                        role: { not: 'deleted' }
                    }
                },
                select: {
                    points: true,
                    reputation: true,
                    badges: true,
                    avatar: true,
                    user: {
                        select: {
                            id: true,
                            fullName: true,
                        }
                    }
                },
                orderBy: [
                    { points: 'desc' },
                    { reputation: 'desc' }
                ],
                take: 50,
            });

            // Flatten structure for easier consumption
            const leaderboard = topUsers.map((p, index) => ({
                rank: index + 1,
                userId: p.user.id,
                name: p.user.fullName,
                points: p.points,
                reputation: p.reputation,
                avatar: p.avatar,
                badges: p.badges,
            }));

            res.json(leaderboard);
        } catch (error) {
            next(error);
        }
    }

    static async getMyRank(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;

            const userProfile = await prisma.profile.findUnique({
                where: { userId },
                select: { points: true }
            });

            if (!userProfile) {
                return res.status(404).json({ message: 'Profile not found' });
            }

            // Find how many users have more points
            const rank = await prisma.profile.count({
                where: {
                    points: { gt: userProfile.points },
                    user: { role: { not: 'deleted' } }
                }
            });

            res.json({
                rank: rank + 1,
                points: userProfile.points
            });
        } catch (error) {
            next(error);
        }
    }
}
