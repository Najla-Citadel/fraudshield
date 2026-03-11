import Queue from 'bull';
import { prisma } from '../config/database';

/**
 * DataRetentionService manages the lifecycle of temporary security data.
 * It periodically purges old security scan records to maintain database 
 * performance and comply with data minimization policies.
 */
export class DataRetentionService {
    private static retentionQueue: Queue.Queue;
    private static isInitialized = false;

    /**
     * Initializes the Bull queue and schedules the daily cleanup job
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

        // Bull Queue Options
        const queueOptions: Queue.QueueOptions = {
            defaultJobOptions: {
                removeOnComplete: true,
                removeOnFail: false,
                attempts: 3,
                backoff: {
                    type: 'exponential',
                    delay: 5000,
                },
            },
        };

        if (typeof redisOptions === 'string') {
            this.retentionQueue = new Queue('data-retention', redisOptions, queueOptions);
        } else {
            queueOptions.redis = redisOptions;
            this.retentionQueue = new Queue('data-retention', queueOptions);
        }

        // Define the worker process
        this.retentionQueue.process(async (job) => {
            console.log(`👷 DataRetention: Processing cleanup job ${job.id}`);
            try {
                await this.purgeOldScans();
                return { status: 'success' };
            } catch (error) {
                console.error(`❌ DataRetention: Error in cleanup job ${job.id}:`, error);
                throw error;
            }
        });

        // Schedule cron job: once a day at 3:00 AM
        const cronInterval = process.env.DATA_RETENTION_CRON || '0 3 * * *';
        console.log(`⏰ DataRetention: Scheduling cleanup with cron: "${cronInterval}"`);

        // Clean up existing repeatable jobs to prevent duplicates
        try {
            const repeatableJobs = await this.retentionQueue.getRepeatableJobs();
            for (const job of repeatableJobs) {
                if (job.id === 'data-retention-purge-recurring') {
                    await this.retentionQueue.removeRepeatableByKey(job.key);
                }
            }
        } catch (error) {
            console.error('⚠️ DataRetention: Failed to clean old jobs:', error);
        }

        // Schedule the recurring job
        await this.retentionQueue.add({}, {
            repeat: { cron: cronInterval },
            jobId: 'data-retention-purge-recurring'
        });

        console.log('⚡ DataRetention Service initialized and cron job scheduled');
        this.isInitialized = true;
    }

    /**
     * Deletes security scan records older than the retention period.
     * Default retention is 90 days if not specified in environment.
     */
    static async purgeOldScans(): Promise<void> {
        const retentionDays = parseInt(process.env.SCAN_RETENTION_DAYS || '90');
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

        console.log(`🧹 DataRetention: Purging scans older than ${retentionDays} days (before ${cutoffDate.toISOString()})`);

        try {
            const deleteResult = await prisma.securityScan.deleteMany({
                where: {
                    createdAt: { lt: cutoffDate }
                }
            });

            console.log(`✅ DataRetention: Successfully purged ${deleteResult.count} old security scan records`);
        } catch (error) {
            console.error('❌ DataRetention: Purge failed:', error);
            throw error;
        }
    }

    /**
     * Graceful shutdown of the queue
     */
    static async shutdown() {
        if (this.retentionQueue) {
            await this.retentionQueue.close();
        }
        console.log('🛑 DataRetention Service shut down');
    }
}
