import Redis from 'ioredis';

let redisClient: Redis | null = null;

export const getRedisClient = (): Redis => {
    if (!redisClient) {
        const redisOptions: any = {
            // Retry with exponential backoff on connection failure
            retryStrategy: (times: number) => {
                const delay = Math.min(times * 100, 3000);
                if (times > 20) {
                    console.error('❌ Redis: Max connection retries (20) reached. Check your REDIS_URL and if the Redis container is healthy.');
                    return null;
                }
                console.log(`🔄 Redis: Connection failed, retrying in ${delay}ms... (Attempt ${times})`);
                return delay;
            },
            lazyConnect: true,
        };

        if (process.env.REDIS_URL) {
            redisClient = new Redis(process.env.REDIS_URL, redisOptions);
        } else {
            redisClient = new Redis({
                ...redisOptions,
                host: process.env.REDIS_HOST || 'localhost',
                port: Number(process.env.REDIS_PORT) || 6380,
                password: process.env.REDIS_PASSWORD || undefined,
            });
        }

        redisClient.on('connect', () => console.log('🔴 Redis client connected'));
        redisClient.on('error', (err) => console.error('🔴 Redis error:', err.message));
    }
    return redisClient;
};
