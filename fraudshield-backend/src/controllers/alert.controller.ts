import { Request, Response, NextFunction } from 'express';
import { AlertEngineService } from '../services/alert-engine.service';
import { prisma } from '../config/database';

/**
 * @openapi
 * tags:
 *   name: Alerts
 *   description: Proactive scam alerts and daily digest
 */
export class AlertController {
    /**
     * @openapi
     * /api/v1/alerts/trending:
     *   get:
     *     summary: Get currently trending scams
     *     tags: [Alerts]
     *     security:
     *       - bearerAuth: []
     *     responses:
     *       200:
     *         description: Successfully retrieved trending alerts
     */
    static async getTrendingAlerts(req: Request, res: Response, next: NextFunction) {
        try {
            // Fetch user preferences
            const userId = req.user!.id;
            const subscription = await (prisma as any).alertSubscription.findUnique({
                where: { userId }
            });
            const userRadius = subscription?.radiusKm || 15;
            const userCategories = (subscription?.categories as string[]) || [];
            const isActive = subscription?.isActive ?? false;

            // Option A: If alerts are disabled, return empty feed with a flag
            if (!isActive) {
                return res.json({
                    trending: [],
                    nearYou: [],
                    alertsDisabled: true
                });
            }

            // Default lookback to 72 hours
            const hours = parseInt(req.query.hours as string) || 72;
            const lat = parseFloat(req.query.lat as string);
            const lng = parseFloat(req.query.lng as string);

            let trending = await AlertEngineService.getTrendingAlerts(hours);

            // Filter trending by categories if user has specified any
            if (userCategories.length > 0) {
                trending = trending.filter(t =>
                    userCategories.some(c => t.category.toLowerCase().includes(c.toLowerCase()))
                );
            }

            let nearYou: any[] = [];
            if (!isNaN(lat) && !isNaN(lng)) {
                // Return just the count of recent local reports to save bandwidth
                let localReports = await AlertEngineService.getAlertsNearLocation(lat, lng, userRadius);

                // Filter localReports by categories if user has specified any
                if (userCategories.length > 0) {
                    localReports = localReports.filter(r =>
                        userCategories.some(c => r.category.toLowerCase().includes(c.toLowerCase()))
                    );
                }

                if (localReports.length > 0) {
                    nearYou = [{
                        reportCount: localReports.length,
                        radius: `${userRadius}km`,
                        message: `${localReports.length} reports logged within ${userRadius}km recently. Stay alert.`,
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
     * @openapi
     * /api/v1/alerts/daily-digest:
     *   get:
     *     summary: Get consolidated daily scam summary
     *     tags: [Alerts]
     *     security:
     *       - bearerAuth: []
     *     responses:
     *       200:
     *         description: Successfully retrieved daily digest
     */
    static async getDailyDigest(req: Request, res: Response, next: NextFunction) {
        try {
            const digest = await AlertEngineService.getDailySummary();
            res.json(digest);
        } catch (error) {
            next(error);
        }
    }

    /**
     * @openapi
     * /api/v1/alerts/subscribe:
     *   post:
     *     summary: Manage user alert preferences
     *     tags: [Alerts]
     *     security:
     *       - bearerAuth: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               categories:
     *                 type: array
     *                 items:
     *                   type: string
     *               latitude:
     *                 type: number
     *               longitude:
     *                 type: number
     *               radiusKm:
     *                 type: integer
     *               emailDigestEnabled:
     *                 type: boolean
     *               isActive:
     *                 type: boolean
     *     responses:
     *       200:
     *         description: Preferences saved successfully
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
                    ...(req.body.emailDigestEnabled !== undefined && { emailDigestEnabled: req.body.emailDigestEnabled }),
                },
                create: {
                    userId,
                    categories: categories || [],
                    latitude,
                    longitude,
                    radiusKm: radiusKm || 15,
                    fcmToken,
                    isActive: isActive ?? true,
                    emailDigestEnabled: req.body.emailDigestEnabled ?? false,
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
    /**
     * @openapi
     * /api/v1/alerts/preferences:
     *   get:
     *     summary: Get user alert preferences
     *     tags: [Alerts]
     *     security:
     *       - bearerAuth: []
     *     responses:
     *       200:
     *         description: Successfully retrieved preferences
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
                    emailDigestEnabled: false,
                });
            }

            res.json(subscription);
        } catch (error) {
            next(error);
        }
    }
}
