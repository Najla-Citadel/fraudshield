import { PrismaClient } from '@prisma/client';
<<<<<<< HEAD

const prisma = new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
    // Connection pool size is configured via DATABASE_URL query params:
    // ?connection_limit=10&pool_timeout=20
    // See .env.prod.example for the recommended production values.
=======
import { MetricsService } from '../services/metrics.service';

const prismaClient = new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

// Extend Prisma with metrics tracking
const prisma = prismaClient.$extends({
    query: {
        async $allOperations({ operation, model, args, query }) {
            const start = Date.now();
            try {
                return await query(args);
            } finally {
                const duration = (Date.now() - start) / 1000;
                MetricsService.dbQueryDuration.observe(
                    { operation, model: model || 'N/A' },
                    duration
                );
            }
        },
    },
>>>>>>> dev-ui2
});

// Test connection on startup (skip in test mode)
if (process.env.NODE_ENV !== 'test') {
    prisma.$connect()
        .then(() => {
            console.log('✅ Database connected successfully');
            if (process.env.DATABASE_URL) {
                const url = new URL(process.env.DATABASE_URL.replace('postgresql://', 'http://')); // URL parser trick
                const limit = url.searchParams.get('connection_limit');
                const timeout = url.searchParams.get('pool_timeout');
                if (limit || timeout) {
                    console.log(`ℹ️ Connection Pool: limit=${limit ?? 'default'}, timeout=${timeout ?? 'default'}s`);
                }
            }
        })
        .catch((error) => {
            console.error('❌ Database connection failed:', error);
        });
}

// Graceful shutdown
process.on('beforeExit', async () => {
    await prisma.$disconnect();
});

export { prisma };
