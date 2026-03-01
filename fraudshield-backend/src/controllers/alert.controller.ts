import { Request, Response, NextFunction } from 'express';
import { AlertEngineService } from '../services/alert-engine.service';
import { AlertService } from '../services/alert.service';
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
    /**
     * @openapi
     * /api/v1/alerts:
     *   get:
     *     summary: Get all personal alerts for the logged-in user
     *     tags: [Alerts]
     *     security:
     *       - bearerAuth: []
     *     responses:
     *       200:
     *         description: List of personal alerts
     */
    static async getUserAlerts(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = req.user!.id;
            const alerts = await AlertService.getUserAlerts(userId);
            res.json(alerts);
        } catch (error) {
            next(error);
        }
    }

    /**
     * @openapi
     * /api/v1/alerts/read-all:
     *   patch:
     *     summary: Mark all unread alerts for the user as read
     *     tags: [Alerts]
     *     security:
     *       - bearerAuth: []
     *     responses:
     *       204:
     *         description: Successfully marked all alerts as read
     */
    static async markAllAsRead(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = req.user!.id;
            await AlertService.markAllAsRead(userId);
            res.status(204).send();
        } catch (error) {
            next(error);
        }
    }

    /**
     * @openapi
     * /api/v1/alerts/{id}/resolve:
     *   post:
     *     summary: Resolve an individual alert with a specific action
     *     tags: [Alerts]
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: string
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               action:
     *                 type: string
     *                 enum: [BLOCK, WHITELIST, DISMISS]
     *     responses:
     *       200:
     *         description: Alert resolved successfully
     */
    static async resolveAlert(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = req.user!.id;
            const { id } = req.params;
            const { action } = req.body as { action: string };
            const alert = await AlertService.resolveAlert(id, userId, action);
            res.json(alert);
        } catch (error) {
            next(error);
        }
    }
    /**
     * Diagnostic endpoint to seed demo alerts for the current user
     */
    static async seedDemoAlerts(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = req.user!.id;
            const { AlertCategory, AlertSeverity } = require('@prisma/client');

            // 1. Welcome Alert
            await AlertService.createAlert({
                userId,
                category: AlertCategory.COMMUNITY,
                severity: AlertSeverity.LOW,
                title: 'Welcome to FraudShield',
                message: 'Your account is now protected. We are monitoring for threats in your area.',
            });

            // 2. System Scan Alert
            await AlertService.createAlert({
                userId,
                category: AlertCategory.SYSTEM_SCAN,
                severity: AlertSeverity.LOW,
                title: 'Initial System Scan Completed',
                message: '0 threats found. Your device security is up to date.',
            });

            // 3. Phishing Alert (High Risk)
            await AlertService.createAlert({
                userId,
                category: AlertCategory.PHISHING,
                severity: AlertSeverity.HIGH,
                title: 'Suspicious activity detected',
                message: 'Your account has been restricted. Please verify your identity at: bit.ly/secure-auth-342',
                metadata: { sender: '+1 (555) ••• 829' }
            });

            res.json({ message: 'Demo alerts seeded successfully' });
        } catch (error) {
            next(error);
        }
    }
}
