import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';

/**
 * @openapi
 * tags:
 *   name: Scam Numbers
 *   description: Scam number cache synchronization for offline protection
 */
export class ScamNumberController {
    /**
     * @openapi
     * /api/v1/features/scam-numbers/sync:
     *   get:
     *     summary: Sync scam number cache for offline protection
     *     description: Returns top reported scam numbers for mobile offline database sync
     *     tags: [Scam Numbers]
     *     security:
     *       - bearerAuth: []
     *     parameters:
     *       - in: query
     *         name: lastSyncedAt
     *         schema:
     *           type: string
     *           format: date-time
     *         description: Return only numbers updated after this timestamp (incremental sync)
     *     responses:
     *       200:
     *         description: Scam numbers retrieved successfully
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 numbers:
     *                   type: array
     *                   items:
     *                     type: object
     *                     properties:
     *                       phoneNumber:
     *                         type: string
     *                       riskScore:
     *                         type: integer
     *                       reportCount:
     *                         type: integer
     *                       verifiedCount:
     *                         type: integer
     *                       categories:
     *                         type: array
     *                         items:
     *                           type: string
     *                       lastReported:
     *                         type: string
     *                         format: date-time
     *                 syncedAt:
     *                   type: string
     *                   format: date-time
     *                 hasMore:
     *                   type: boolean
     */
    static async syncScamNumbers(req: Request, res: Response, next: NextFunction) {
        try {
            const { lastSyncedAt } = req.query;

            // Parse lastSyncedAt or default to epoch (return all)
            const syncTimestamp = lastSyncedAt
                ? new Date(lastSyncedAt as string)
                : new Date(0);

            // Validate timestamp
            if (isNaN(syncTimestamp.getTime())) {
                return res.status(400).json({
                    error: 'Invalid lastSyncedAt timestamp'
                });
            }

            // Query scam numbers updated after the last sync
            const numbers = await prisma.scamNumberCache.findMany({
                where: {
                    updatedAt: { gt: syncTimestamp }
                },
                orderBy: { riskScore: 'desc' },
                take: 5000,
                select: {
                    phoneNumber: true,
                    riskScore: true,
                    reportCount: true,
                    verifiedCount: true,
                    categories: true,
                    lastReported: true,
                    updatedAt: true,
                },
            });

            // Parse categories JSON for each entry
            const formattedNumbers = numbers.map(num => ({
                phoneNumber: num.phoneNumber,
                riskScore: num.riskScore,
                reportCount: num.reportCount,
                verifiedCount: num.verifiedCount,
                categories: typeof num.categories === 'string'
                    ? JSON.parse(num.categories)
                    : num.categories,
                lastReported: num.lastReported.toISOString(),
                updatedAt: num.updatedAt.toISOString(),
            }));

            res.json({
                numbers: formattedNumbers,
                syncedAt: new Date().toISOString(),
                hasMore: false, // We return all matches (max 5000)
                count: formattedNumbers.length,
            });

        } catch (error) {
            next(error);
        }
    }

    /**
     * Get cache statistics (for debugging/monitoring)
     */
    static async getCacheStats(req: Request, res: Response, next: NextFunction) {
        try {
            const [totalCount, highRiskCount, criticalCount, avgRiskScore, oldestEntry, newestEntry] = await Promise.all([
                prisma.scamNumberCache.count(),
                prisma.scamNumberCache.count({ where: { riskScore: { gte: 55 } } }),
                prisma.scamNumberCache.count({ where: { riskScore: { gte: 80 } } }),
                prisma.scamNumberCache.aggregate({
                    _avg: { riskScore: true }
                }),
                prisma.scamNumberCache.findFirst({
                    orderBy: { lastReported: 'asc' },
                    select: { lastReported: true }
                }),
                prisma.scamNumberCache.findFirst({
                    orderBy: { lastReported: 'desc' },
                    select: { lastReported: true }
                }),
            ]);

            res.json({
                totalNumbers: totalCount,
                highRiskNumbers: highRiskCount,
                criticalNumbers: criticalCount,
                averageRiskScore: Math.round(avgRiskScore._avg.riskScore || 0),
                oldestReport: oldestEntry?.lastReported.toISOString(),
                newestReport: newestEntry?.lastReported.toISOString(),
            });
        } catch (error) {
            next(error);
        }
    }
}
