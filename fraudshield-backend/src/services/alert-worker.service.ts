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

        // Support for REDIS_URL or individual host/port environment variables
        // Defaults to localhost:6380 to match local Docker setup when REDIS_PORT is missing
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

        console.log(`📶 Bull Queue: Attempting to connect to Redis at ${connectionString}`);

        if (!process.env.REDIS_HOST || !process.env.REDIS_PORT) {
            if (typeof redisOptions !== 'string') {
                console.log('⚠️  Bull Queue: Using default connection parameters (localhost:6380). Ensure your .env is correctly configured for production.');
            }
        }

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

        // If using a host/port object, it must be nested under 'redis' in options
        // If using a URL string, it can be passed as the second argument
        if (typeof redisOptions === 'string') {
            this.trendingAlertQueue = new Queue('trending-alerts', redisOptions, queueOptions);
        } else {
            queueOptions.redis = redisOptions;
            this.trendingAlertQueue = new Queue('trending-alerts', queueOptions);
        }

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
