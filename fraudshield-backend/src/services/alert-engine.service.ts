import { prisma } from '../config/database';
import * as admin from 'firebase-admin';
import { getRedisClient } from '../config/redis';
import logger from '../utils/logger';

export class AlertEngineService {
    /**
     * Aggregates ScamReports from the last `hours` to find trending categories
     */
    static async getTrendingAlerts(hours: number = 72) {
        const timeWindow = new Date(Date.now() - hours * 60 * 60 * 1000);

        // Fetch recent reports
        const recentReports = await prisma.scamReport.findMany({
            where: {
                createdAt: { gte: timeWindow },
                isPublic: true,
                deletedAt: null,
            },
            include: {
                _count: { select: { verifications: true } }
            }
        });

        // Aggregate by category
        const categoryCounts: Record<string, { count: number, verifiedCount: number, latest: Date }> = {};

        recentReports.forEach(report => {
            if (!categoryCounts[report.category]) {
                categoryCounts[report.category] = { count: 0, verifiedCount: 0, latest: report.createdAt };
            }
            categoryCounts[report.category].count++;
            if (report._count.verifications > 0) {
                categoryCounts[report.category].verifiedCount++;
            }
            if (report.createdAt > categoryCounts[report.category].latest) {
                categoryCounts[report.category].latest = report.createdAt;
            }
        });

        // Format into trending alerts, sorted by count descending
        const trending = Object.entries(categoryCounts)
            .map(([category, stats]) => {
                let severity = 'low';
                if (stats.count >= 10 || stats.verifiedCount >= 3) severity = 'high';
                else if (stats.count >= 3 || stats.verifiedCount >= 1) severity = 'medium';

                // Generate a dynamic title/desc based on category
                let title = `${category} Surge Detected`;
                let description = `We've detected an unusually high number of ${category.toLowerCase()}s recently.`;

                if (category.toLowerCase().includes('job')) {
                    title = 'Fake Job Offers Trending';
                    description = `Watch out for "easy money" part-time job offers. Never pay an upfront deposit.`;
                } else if (category.toLowerCase().includes('investment')) {
                    title = 'Investment Scam Warning';
                    description = `High-yield investment groups are highly active right now. Be skeptical of guaranteed returns.`;
                } else if (category.toLowerCase().includes('phishing')) {
                    title = 'Phishing Links Surging';
                    description = `Be careful clicking links via SMS or WhatsApp, especially messages claiming your account is blocked.`;
                }

                return {
                    id: `trend-${category.toLowerCase().replace(/\s+/g, '-')}-${Date.now()}`,
                    category,
                    title,
                    description,
                    reportCount: stats.count,
                    verifiedCount: stats.verifiedCount,
                    timeframe: `${hours}h`,
                    severity,
                    latestReportAt: stats.latest,
                };
            })
            .sort((a, b) => b.reportCount - a.reportCount);

        return trending;
    }

    /**
     * Gets reports near a specific latitude/longitude
     */
    static async getAlertsNearLocation(lat: number, lng: number, radiusKm: number = 15) {
        // Very basic radius calculation for the mock (Haversine approximation usually better for production)
        const latDelta = radiusKm / 111.0;
        const lngDelta = radiusKm / (111.0 * Math.cos(lat * (Math.PI / 180)));

        const localReports = await prisma.scamReport.findMany({
            where: {
                isPublic: true,
                deletedAt: null,
                latitude: { gte: lat - latDelta, lte: lat + latDelta },
                longitude: { gte: lng - lngDelta, lte: lng + lngDelta }
            },
            take: 50,
            orderBy: { createdAt: 'desc' }
        });

        return localReports;
    }

    // NOTE: Deduplication is now handled per-method via Redis TTL (see below).
    // This in-memory set is kept only as a fast pre-check fallback.

    /**
     * Identifies trending alerts and dispatches FCM notifications to subscribed users
     */
    static async dispatchTrendingAlerts() {
        logger.info('🔍 Running trending alerts analysis...');
        const trends = await this.getTrendingAlerts(72);

        // Only trigger push notifications for HIGH severity trends
        const actionableTrends = trends.filter(trend => trend.severity === 'high');

        if (actionableTrends.length === 0) {
            logger.info('✅ No high-severity trends detected.');
            return;
        }

        const trendMap = new Map(actionableTrends.map(t => [t.category, t]));

        const subscribers = await (prisma as any).alertSubscription.findMany({
            where: {
                isActive: true,
                fcmToken: { not: null }
            }
        });

        logger.info(`📡 Found ${subscribers.length} active alert subscribers.`);
        let dispatchCount = 0;
        const redis = getRedisClient();
        // Stable date key — changes once per day, so each user gets at most 1 alert/category/day
        const today = new Date().toISOString().slice(0, 10); // e.g. "2026-02-23"

        for (const sub of subscribers) {
            const userCategories = sub.categories as string[];

            for (const trendingCategory of trendMap.keys()) {
                const isMatch = userCategories.length === 0 || userCategories.some(cat =>
                    trendingCategory.toLowerCase().includes(cat.toLowerCase())
                );

                if (isMatch) {
                    const trend = trendMap.get(trendingCategory)!;

                    // Redis key is stable within a calendar day — immune to restarts and report count changes
                    const cacheKey = `alert:trending:${sub.userId}:${trend.category}:${today}`;

                    try {
                        const alreadySent = await redis.get(cacheKey);
                        if (alreadySent) {
                            continue; // Already notified today — skip
                        }

                        const fcmTimeout = new Promise((_, reject) =>
                            setTimeout(() => reject(new Error('FCM timeout')), 5000)
                        );

                        await Promise.race([
                            admin.messaging().send({
                                token: sub.fcmToken,
                                notification: {
                                    title: trend.title,
                                    body: trend.description,
                                },
                                data: {
                                    type: 'trending_alert',
                                    severity: trend.severity,
                                    category: trend.category,
                                    reportCount: trend.reportCount.toString()
                                },
                                android: {
                                    notification: {
                                        channelId: 'high_importance_channel',
                                        priority: 'high',
                                    }
                                }
                            }),
                            fcmTimeout
                        ]);

                        // Mark as sent in Redis for 24 hours 
                        await redis.set(cacheKey, '1', 'EX', 86400);
                        dispatchCount++;
                        break; // One alert per user per dispatcher run
                    } catch (error) {
                        logger.error(`❌ FCM Trending Alert failed:`, { error });
                    }
                }
            }
        }
        logger.info(`🚀 Dispatched ${dispatchCount} trending push notifications.`);
    }

    /**
     * Finds nearby subscribers and sends an immediate push notification for a new report
     */
    static async dispatchLocalAlert(report: any) {
        if (!report.latitude || !report.longitude || !report.isPublic) return;

        logger.info(`📍 Processing local alert for Report ${report.id} at (${report.latitude}, ${report.longitude})`);

        const subscribers = await (prisma as any).alertSubscription.findMany({
            where: {
                isActive: true,
                fcmToken: { not: null },
                userId: { not: report.userId }
            }
        });

        const notifications: Promise<any>[] = [];
        const redis = getRedisClient();
        // Local alerts: cap at once per user per category per hour (not per day, since these are real-time reports)
        const hourSlot = new Date().toISOString().slice(0, 13); // e.g. "2026-02-23T16"

        for (const sub of subscribers) {
            if (sub.latitude === null || sub.longitude === null) continue;

            const distance = this.calculateDistance(
                report.latitude, report.longitude,
                sub.latitude, sub.longitude
            );

            if (distance <= (sub.radiusKm || 15)) {
                const userCategories = sub.categories as string[];
                const isMatch = userCategories.length === 0 || userCategories.some(cat =>
                    report.category.toLowerCase().includes(cat.toLowerCase())
                );

                if (isMatch) {
                    // Deduplicate: one local notification per user per category per hour
                    const cacheKey = `alert:local:${sub.userId}:${report.category}:${hourSlot}`;
                    const alreadySent = await redis.get(cacheKey).catch(() => null);
                    if (alreadySent) continue;

                    notifications.push(
                        admin.messaging().send({
                            token: sub.fcmToken,
                            notification: {
                                title: '🚨 Scam Reported Near You',
                                body: `A new ${report.category} scam was just reported within ${distance.toFixed(1)}km of your location.`,
                            },
                            data: {
                                type: 'local_alert',
                                reportId: report.id,
                                category: report.category,
                                distance: distance.toFixed(1)
                            },
                            android: {
                                notification: {
                                    channelId: 'high_importance_channel',
                                    priority: 'high',
                                }
                            }
                        })
                            .then(() => redis.set(cacheKey, '1', 'EX', 3600)) // Mark as sent for 1 hour
                            .catch(err => logger.error(`❌ FCM Local Alert failed:`, { error: err }))
                    );
                }
            }
        }

        if (notifications.length > 0) {
            await Promise.all(notifications);
            logger.info(`🚀 Sent ${notifications.length} local push notifications.`);
        }
    }


    /**
     * Haversine formula to calculate distance between two points in km
     */
    private static calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
        const R = 6371; // Earth's radius in km
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLon = (lon2 - lon1) * Math.PI / 180;
        const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
