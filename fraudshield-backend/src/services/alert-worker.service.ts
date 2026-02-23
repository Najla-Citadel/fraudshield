import Queue from 'bull';
import { AlertEngineService } from './alert-engine.service';

/**
 * AlertWorkerService handles background job scheduling for trending alerts.
 * It uses Bull (backed by Redis) to manage queues and ensure jobs are processed
 * reliably without blocking the main event loop.
 */
export class AlertWorkerService {
    private static trendingAlertQueue: Queue.Queue;
    private static isInitialized = false;

    /**
     * Initializes the Bull queue and sets up the worker process
     */
    static initialize() {
        if (this.isInitialized) return;

        const redisOptions = {
            host: process.env.REDIS_HOST || 'localhost',
            port: Number(process.env.REDIS_PORT) || 6380,
            password: process.env.REDIS_PASSWORD,
        };

        this.trendingAlertQueue = new Queue('trending-alerts', {
            redis: redisOptions,
            defaultJobOptions: {
                removeOnComplete: true,
                removeOnFail: false, // Keep failed jobs for debugging
                attempts: 3,
                backoff: {
                    type: 'exponential',
                    delay: 5000,
                },
            },
        });

        // 🏗️ Define the worker process
        this.trendingAlertQueue.process(async (job) => {
            console.log(`👷 Worker: Processing job ${job.id} (${job.name})`);
            try {
                await AlertEngineService.dispatchTrendingAlerts();
                return { status: 'success' };
            } catch (error) {
                console.error(`❌ Worker Error in job ${job.id}:`, error);
                throw error; // Re-throw to trigger Bull's retry logic
            }
        });

        // 📅 Schedule the recurring job (Check for trends every 5 minutes in production)
        // For development/demo, we'll keep it at 1 minute as requested
        this.trendingAlertQueue.add({}, {
            repeat: { cron: '*/1 * * * *' }, // Every minute
            jobId: 'trending-analysis-recurring'
        });

        this.trendingAlertQueue.on('error', (error) => {
            console.error('🔴 Bull Queue Error:', error);
        });

        console.log('⚡ Alert Worker Service initialized and cron job scheduled');
        this.isInitialized = true;
    }

    /**
     * Graceful shutdown of the queue
     */
    static async shutdown() {
        if (this.trendingAlertQueue) {
            await this.trendingAlertQueue.close();
            console.log('🛑 Alert Worker Service shut down');
        }
    }
}
