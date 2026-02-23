import { Request, Response, NextFunction } from 'express';
import { AlertEngineService } from '../services/alert-engine.service';
import { prisma } from '../config/database';

export class AlertController {
    /**
     * GET /api/alerts/trending
     * Returns aggressive aggregations of recent scams
     */
    static async getTrendingAlerts(req: Request, res: Response, next: NextFunction) {
        try {
            // Default lookback to 72 hours
            const hours = parseInt(req.query.hours as string) || 72;
            const lat = parseFloat(req.query.lat as string);
            const lng = parseFloat(req.query.lng as string);

            const trending = await AlertEngineService.getTrendingAlerts(hours);

            let nearYou = [];
            if (!isNaN(lat) && !isNaN(lng)) {
                // Return just the count of recent local reports to save bandwidth
                const localReports = await AlertEngineService.getAlertsNearLocation(lat, lng, 15);

                if (localReports.length > 0) {
                    nearYou = [{
                        reportCount: localReports.length,
                        radius: '15km',
                        message: `${localReports.length} reports logged near your area recently. Stay alert.`,
                        latestReport: localReports[0],
                    }];
                }
            }

            res.json({
                trending,
                nearYou
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/alerts/subscribe
     * Manage user preferences for push alerts
     */
    static async subscribeToAlerts(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = req.user!.id;
            const { categories, latitude, longitude, radiusKm, fcmToken, isActive } = req.body;

            const subscription = await (prisma as any).alertSubscription.upsert({
                where: { userId },
                update: {
                    ...(categories && { categories }),
                    ...(latitude !== undefined && { latitude }),
                    ...(longitude !== undefined && { longitude }),
                    ...(radiusKm && { radiusKm }),
                    ...(fcmToken && { fcmToken }),
                    ...(isActive !== undefined && { isActive }),
                },
                create: {
                    userId,
                    categories: categories || [],
                    latitude,
                    longitude,
                    radiusKm: radiusKm || 15,
                    fcmToken,
                    isActive: isActive ?? true,
                },
            });

            res.json(subscription);
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/alerts/preferences
     * Retrieve current user subscription preferences
     */
    static async getPreferences(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = req.user!.id;
            const subscription = await (prisma as any).alertSubscription.findUnique({
                where: { userId },
            });

            if (!subscription) {
                // Return sensible defaults if they haven't set up yet
                return res.json({
                    categories: [],
                    isActive: false,
                    radiusKm: 15,
                });
            }

            res.json(subscription);
        } catch (error) {
            next(error);
        }
    }
}
