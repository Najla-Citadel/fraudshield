import { Request, Response, NextFunction } from 'express';
import { BadgeService } from '../services/badge.service';
import { prisma } from '../config/database';

export class BadgeController {
    /**
     * Get user's earned badges and the full list of available badges
     */
    static async getMyBadges(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const fullLibrary = await BadgeService.getBadgeLibrary(userId);

            const earned = fullLibrary.filter(b => b.isEarned);
            const available = fullLibrary.filter(b => !b.isEarned);

            res.json({
                earned,
                available,
                totalCount: fullLibrary.length,
                earnedCount: earned.length
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Get all available badge definitions
     */
    static async getAllBadges(req: Request, res: Response, next: NextFunction) {
        try {
            const definitions = await (prisma as any).badgeDefinition.findMany({
                orderBy: [
                    { tier: 'asc' },
                    { name: 'asc' }
                ]
            });
            res.json(definitions);
        } catch (error) {
            next(error);
        }
    }
}
