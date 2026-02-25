import Redis from 'ioredis';

let redisClient: Redis | null = null;

export const getRedisClient = (): Redis => {
    if (!redisClient) {
        redisClient = new Redis({
            host: process.env.REDIS_HOST || 'localhost',
            port: Number(process.env.REDIS_PORT) || 6380,
            password: process.env.REDIS_PASSWORD || undefined,
            // Retry up to 3 times on connection failure
            retryStrategy: (times) => {
                if (times > 3) {
                    console.error('❌ Redis: max retries reached, giving up.');
                    return null;
                }
                return Math.min(times * 200, 1000);
            },
            lazyConnect: true,
        });

        redisClient.on('connect', () => console.log('🔴 Redis client connected'));
        redisClient.on('error', (err) => console.error('🔴 Redis error:', err.message));
    }
    return redisClient;
};
