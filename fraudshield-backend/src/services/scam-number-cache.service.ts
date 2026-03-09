import Queue from 'bull';
import { prisma } from '../config/database';
import { EncryptionUtils } from '../utils/encryption';

/**
 * ScamNumberCacheService manages a high-performance cache of top reported scam numbers.
 * It aggregates community reports, calculates risk scores, and provides a sync endpoint
 * for mobile clients to download for offline scam detection.
 */
export class ScamNumberCacheService {
    private static cacheQueue: Queue.Queue;
    private static isInitialized = false;

    /**
     * Initializes the Bull queue and schedules periodic cache refresh
     */
    static async initialize() {
        if (this.isInitialized) return;

        // Redis connection configuration
        const host = process.env.REDIS_HOST || 'localhost';
        const port = Number(process.env.REDIS_PORT) || 6380;
        const password = process.env.REDIS_PASSWORD || undefined;

        const redisOptions: any = process.env.REDIS_URL
            ? process.env.REDIS_URL
            : {
                host,
                port,
                password,
            };

        const connectionString = typeof redisOptions === 'string'
            ? 'via REDIS_URL'
            : `${host}:${port}`;

        console.log(`📶 Scam Cache Queue: Attempting to connect to Redis at ${connectionString}`);

        // Bull Queue Options
        const queueOptions: Queue.QueueOptions = {
            defaultJobOptions: {
                removeOnComplete: true,
                removeOnFail: false, // Keep failed jobs for debugging
                attempts: 3,
                backoff: {
                    type: 'exponential',
                    delay: 5000,
                },
            },
        };

        // Create queue
        if (typeof redisOptions === 'string') {
            this.cacheQueue = new Queue('scam-cache-refresh', redisOptions, queueOptions);
        } else {
            queueOptions.redis = redisOptions;
            this.cacheQueue = new Queue('scam-cache-refresh', queueOptions);
        }

        // Define the worker process
        this.cacheQueue.process(async (job) => {
            console.log(`👷 Worker: Processing scam cache refresh job ${job.id}`);
            try {
                await this.refreshCache();
                return { status: 'success' };
            } catch (error) {
                console.error(`❌ Worker Error in cache refresh job ${job.id}:`, error);
                throw error;
            }
        });

        // Schedule cron job: every 6 hours
        const cronInterval = process.env.SCAM_CACHE_REFRESH_CRON || '0 */6 * * *';

        console.log(`⏰ Scam Cache Queue: Scheduling cache refresh with cron: "${cronInterval}"`);

        // Clean up existing repeatable jobs
        try {
            const repeatableJobs = await this.cacheQueue.getRepeatableJobs();
            for (const job of repeatableJobs) {
                if (job.id === 'scam-cache-refresh-recurring') {
                    await this.cacheQueue.removeRepeatableByKey(job.key);
                    console.log('🧹 Scam Cache Queue: Removed old repeatable job');
                }
            }
        } catch (error) {
            console.error('⚠️ Scam Cache Queue: Failed to clean old jobs:', error);
        }

        // Schedule the recurring job
        await this.cacheQueue.add({}, {
            repeat: { cron: cronInterval },
            jobId: 'scam-cache-refresh-recurring'
        });

        this.cacheQueue.on('error', (error) => {
            console.error('🔴 Scam Cache Queue Error:', error);
        });

        console.log('⚡ Scam Cache Service initialized and cron job scheduled');
        this.isInitialized = true;

        // Run initial cache refresh
        console.log('🔄 Running initial scam number cache refresh...');
        await this.refreshCache();
    }

    /**
     * Refresh the scam number cache by aggregating top reported numbers
     */
    static async refreshCache(): Promise<void> {
        console.log('📊 ScamCache: Starting cache refresh...');
        const startTime = Date.now();

        try {
            // 1. Query top reported phone numbers (public, not deleted, with at least 3 reports)
            const scamReports = await prisma.scamReport.groupBy({
                by: ['target'],
                where: {
                    targetType: 'phone',
                    isPublic: true,
                    deletedAt: null,
                    target: { not: null },
                },
                _count: {
                    id: true,
                },
                having: {
                    id: {
                        _count: {
                            gte: 3, // Minimum 3 reports to be cached
                        }
                    }
                },
                orderBy: {
                    _count: {
                        id: 'desc',
                    }
                },
                take: 5000, // Top 5000 numbers
            });

            console.log(`📊 ScamCache: Found ${scamReports.length} phone numbers with 3+ reports`);

            // 2. For each number, calculate detailed metrics
            const cacheEntries = [];

            for (const group of scamReports) {
                if (!group.target) continue;

                try {
                    // Decrypt the phone number for metrics calculation
                    const decryptedNumber = await EncryptionUtils.decrypt(group.target);

                    // Get detailed report data for this number
                    const reports = await prisma.scamReport.findMany({
                        where: {
                            target: group.target,
                            targetType: 'phone',
                            isPublic: true,
                            deletedAt: null,
                        },
                        include: {
                            verifications: true,
                            user: {
                                include: { profile: true }
                            }
                        },
                        orderBy: { createdAt: 'desc' },
                        take: 50, // Limit for performance
                    });

                    const totalReports = reports.length;
                    let verifiedReports = 0;
                    let totalReputation = 0;
                    let latestDate: Date | null = null;
                    const categoriesSet = new Set<string>();

                    for (const report of reports) {
                        // Count verified reports
                        const positiveVerifications = report.verifications.filter(v => v.isSame).length;
                        if (positiveVerifications > 0) verifiedReports++;

                        // Sum reputation
                        const rep = report.user?.profile?.reputation ?? 0;
                        totalReputation += rep;

                        // Track latest date
                        if (!latestDate || report.createdAt > latestDate) {
                            latestDate = report.createdAt;
                        }

                        // Collect unique categories
                        if (report.category) {
                            categoriesSet.add(report.category);
                        }
                    }

                    // Calculate risk score using same algorithm as RiskEvaluationService
                    const avgReporterReputation = totalReports > 0 ? totalReputation / totalReports : 0;
                    const daysSinceLastReport = latestDate
                        ? (Date.now() - latestDate.getTime()) / (1000 * 60 * 60 * 24)
                        : 999;

                    const communityScore = this.calcCommunityScore(totalReports);
                    const verRatioScore = this.calcVerificationRatioScore(verifiedReports, totalReports);
                    const repScore = this.calcReputationScore(avgReporterReputation);
                    const recencyScore = this.calcRecencyScore(daysSinceLastReport);

                    const rawScore =
                        communityScore * 0.35 +
                        verRatioScore * 0.30 +
                        repScore * 0.20 +
                        recencyScore * 0.15;

                    const riskScore = Math.round(Math.min(rawScore, 100));

                    // Only cache numbers with meaningful risk (score > 30)
                    if (riskScore >= 30) {
                        cacheEntries.push({
                            phoneNumber: decryptedNumber,
                            riskScore,
                            reportCount: totalReports,
                            verifiedCount: verifiedReports,
                            categories: JSON.stringify(Array.from(categoriesSet)),
                            lastReported: latestDate || new Date(),
                            updatedAt: new Date(),
                        });
                    }
                } catch (error) {
                    console.error(`⚠️ ScamCache: Failed to process number:`, error);
                    continue;
                }
            }

            console.log(`📊 ScamCache: Prepared ${cacheEntries.length} cache entries (filtered by risk >= 30)`);

            // 3. Batch upsert to ScamNumberCache table
            if (cacheEntries.length > 0) {
                await prisma.$transaction(
                    cacheEntries.map(entry =>
                        prisma.scamNumberCache.upsert({
                            where: { phoneNumber: entry.phoneNumber },
                            update: entry,
                            create: entry,
                        })
                    )
                );

                console.log(`✅ ScamCache: Upserted ${cacheEntries.length} entries`);
            }

            // 4. Cleanup old entries (last reported > 90 days ago)
            const cutoffDate = new Date();
            cutoffDate.setDate(cutoffDate.getDate() - 90);

            const deleteResult = await prisma.scamNumberCache.deleteMany({
                where: {
                    lastReported: { lt: cutoffDate }
                }
            });

            console.log(`🧹 ScamCache: Cleaned up ${deleteResult.count} old entries (>90 days)`);

            const duration = Date.now() - startTime;
            console.log(`✅ ScamCache: Refresh completed in ${duration}ms`);

        } catch (error) {
            console.error('❌ ScamCache: Refresh failed:', error);
            throw error;
        }
    }

    /**
     * Get top scam numbers from cache
     */
    static async getTopScamNumbers(limit: number = 5000): Promise<any[]> {
        return prisma.scamNumberCache.findMany({
            orderBy: { riskScore: 'desc' },
            take: limit,
        });
    }

    /**
     * Get cached risk score for a specific number
     */
    static async getCachedRisk(phoneNumber: string): Promise<number | null> {
        const cached = await prisma.scamNumberCache.findUnique({
            where: { phoneNumber },
        });
        return cached ? cached.riskScore : null;
    }

    // ── Risk Scoring Methods (mirrored from RiskEvaluationService) ───

    /** Maps report count to a 0–100 score using a logarithmic curve */
    private static calcCommunityScore(totalReports: number): number {
        if (totalReports === 0) return 0;
        return Math.min(10 * Math.log2(totalReports + 1) * 3, 100);
    }

    /** % of reports that got verified as scam (0–100) */
    private static calcVerificationRatioScore(verified: number, total: number): number {
        if (total === 0) return 0;
        return (verified / total) * 100;
    }

    /** Scales reporter reputation (average) to a 0–100 score */
    private static calcReputationScore(avgRep: number): number {
        return Math.min((avgRep / 200) * 100, 100);
    }

    /** More recent = higher risk score. Old reports decay. */
    private static calcRecencyScore(daysSince: number): number {
        if (daysSince >= 999) return 0;
        if (daysSince <= 1) return 100;
        if (daysSince <= 7) return 80;
        if (daysSince <= 30) return 50;
        if (daysSince <= 90) return 30;
        return 10;
    }

    /**
     * Graceful shutdown of the queue
     */
    static async shutdown() {
        if (this.cacheQueue) {
            await this.cacheQueue.close();
        }
        console.log('🛑 Scam Cache Service shut down');
    }
}
