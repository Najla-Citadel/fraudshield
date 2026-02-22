import { prisma } from '../config/database';

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
                latitude: { gte: lat - latDelta, lte: lat + latDelta },
                longitude: { gte: lng - lngDelta, lte: lng + lngDelta }
            },
            take: 50,
            orderBy: { createdAt: 'desc' }
        });

        return localReports;
    }
}
