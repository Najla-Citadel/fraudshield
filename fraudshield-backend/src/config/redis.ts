import Redis from 'ioredis';

let redisClient: Redis | null = null;

export const getRedisClient = (): Redis => {
    if (!redisClient) {
        const redisOptions: any = {
            // Retry up to 3 times on connection failure
            retryStrategy: (times: number) => {
                if (times > 3) {
                    console.error('❌ Redis: max retries reached, giving up.');
                    return null;
                }
                return Math.min(times * 200, 1000);
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
