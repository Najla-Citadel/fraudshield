import { Request, Response } from 'express';
import { prisma } from '../config/database';
import { AlertEngineService } from '../services/alert-engine.service';

export class TrendingController {
    /**
     * Replaces the previous static/simplified logic with the full AlertEngineService.
     * This ensures the mobile app Trends tab stays in sync with push notifications
     * and utilizes the system's 72-hour aggregation window.
     */
    public static async getTrendingScams(req: Request, res: Response) {
        try {
            // 1. Get trending categories from the core engine (72h window)
            const historicalTrends = await AlertEngineService.getTrendingAlerts(72);

            // 2. Enhance trends with real-world examples from the database
            const enhancedTrends = await Promise.all(
                historicalTrends.map(async (trend) => {
                    // Fetch the most recent verified or public report for THIS category
                    const report = await prisma.scamReport.findFirst({
                        where: {
                            category: trend.category,
                            isPublic: true,
                            deletedAt: null,
                        },
                        orderBy: {
                            createdAt: 'desc',
                        },
                    });

                    // Map engine severity to UI colors/badges
                    let badgeColor = '#3B82F6'; // Default Blue (Emerging)
                    let badgeText = trend.severity.toUpperCase();

                    if (trend.severity === 'high') {
                        badgeColor = '#EF4444'; // Red (Critical)
                    } else if (trend.severity === 'medium') {
                        badgeColor = '#F97316'; // Orange (High Growth)
                    }

                    // Extract a representative "Example" hook from the report evidence
                    let example = null;
                    if (report) {
                        const evidence = report.evidence as any;
                        if (evidence && (evidence.smsContent || evidence.message || evidence.callerName)) {
                            example = {
                                sender: report.target || evidence.callerName || 'Unknown Source',
                                message: evidence.smsContent || evidence.message || report.description,
                                link: report.targetType === 'URL' ? report.target : '',
                            };
                        } else if (report.targetType === 'URL') {
                            example = {
                                sender: 'Unknown Source',
                                message: report.description,
                                link: report.target,
                            };
                        }
                    }

                    // Humanize the timestamp based on the latest report in this trend
                    const diffMs = Date.now() - new Date(trend.latestReportAt).getTime();
                    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
                    const diffMinutes = Math.floor(diffMs / (1000 * 60));
                    
                    let timestampStr = 'Updated just now';
                    if (diffHours >= 24) {
                        timestampStr = `Updated ${Math.floor(diffHours / 24)}d ago`;
                    } else if (diffHours > 0) {
                        timestampStr = `Updated ${diffHours}h ago`;
                    } else if (diffMinutes > 0) {
                        timestampStr = `Updated ${diffMinutes}m ago`;
                    }

                    return {
                        id: trend.id,
                        title: trend.title,
                        description: trend.description,
                        badgeText: badgeText === 'HIGH' ? 'HIGH GROWTH' : 
                                  badgeText === 'MEDIUM' ? 'STABLE' : 
                                  badgeText === 'LOW' ? 'EMERGING' : badgeText,
                        badgeColor,
                        timestamp: timestampStr,
                        example,
                        safetyTips: [
                            'Always verify the source independently.',
                            'Never share OTPs, passwords, or personal details.',
                            'Report suspicious activity to authorities immediately.'
                        ],
                        isExpanded: false,
                        reportCount: trend.reportCount,
                        verifiedCount: trend.verifiedCount,
                    };
                })
            );

            res.json({
                status: 'success',
                data: enhancedTrends,
            });
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}
