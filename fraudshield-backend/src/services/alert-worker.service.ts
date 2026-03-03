import Queue from 'bull';
import { AlertEngineService } from './alert-engine.service';
    private static dailyDigestQueue: Queue.Queue;
    private static isInitialized = false;

    /**
     * Initializes the Bull queue and sets up the worker process
     */
    static async initialize() {
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
            this.dailyDigestQueue = new Queue('daily-digest', redisOptions, queueOptions);
        } else {
            queueOptions.redis = redisOptions;
            this.trendingAlertQueue = new Queue('trending-alerts', queueOptions);
            this.dailyDigestQueue = new Queue('daily-digest', queueOptions);
        }

        // 🏗️ Define the worker process
        this.trendingAlertQueue.process(async (job) => {
            console.log(`👷 Worker: Processing trending alert job ${job.id}`);
            try {
                await AlertEngineService.dispatchTrendingAlerts();
                return { status: 'success' };
            } catch (error) {
                console.error(`❌ Worker Error in trending job ${job.id}:`, error);
                throw error;
            }
        });

        this.dailyDigestQueue.process(async (job) => {
            console.log(`👷 Worker: Processing daily digest job ${job.id}`);
            try {
                const digest = await AlertEngineService.getDailySummary();

                // Find users who opted in
                const subscribers = await (prisma as any).alertSubscription.findMany({
                    where: {
                        emailDigestEnabled: true,
                        isActive: true
                    },
                    include: { user: true }
                });

                console.log(`📧 Worker: Sending daily digest to ${subscribers.length} opted-in users...`);

                for (const sub of subscribers) {
                    if (sub.user.email) {
                        try {
                            const { EmailService } = require('./email.service');
                            await EmailService.sendDailyDigestEmail(sub.user.email, digest);
                        } catch (emailErr) {
                            console.error(`❌ Failed to send digest email to ${sub.user.email}:`, emailErr);
                        }
                    }
                }

                return { status: 'success' };
            } catch (error) {
                console.error(`❌ Worker Error in digest job ${job.id}:`, error);
                throw error;
            }
        });

        // 📅 Schedule the recurring job (Configurable via TRENDING_ALERT_CRON)
        // Defaults to once per hour in absolute time (e.g. 10:00, 11:00)
        const cronInterval = process.env.TRENDING_ALERT_CRON || '0 * * * *';

        console.log(`⏰ Bull Queue: Scheduling trending analysis with cron: "${cronInterval}"`);

        // Clean up any existing repeatable jobs with this ID to prevent duplicates when cron changes
        try {
            const repeatableJobs = await this.trendingAlertQueue.getRepeatableJobs();
            for (const job of repeatableJobs) {
                if (job.id === 'trending-analysis-recurring') {
                    await this.trendingAlertQueue.removeRepeatableByKey(job.key);
                    console.log('🧹 Bull Queue: Removed old repeatable job');
                }
            }
        } catch (error) {
            console.error('⚠️ Bull Queue: Failed to clean old jobs:', error);
        }

        await this.trendingAlertQueue.add({}, {
            repeat: { cron: cronInterval },
            jobId: 'trending-analysis-recurring'
        });

        }
        if (this.dailyDigestQueue) {
            await this.dailyDigestQueue.close();
        }
        console.log('🛑 Alert Worker Service shut down');
    }
}
