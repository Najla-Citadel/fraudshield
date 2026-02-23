import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
    // Connection pool size is configured via DATABASE_URL query params:
    // ?connection_limit=10&pool_timeout=20
    // See .env.prod.example for the recommended production values.
});

// Test connection on startup
prisma.$connect()
    .then(() => {
        console.log('✅ Database connected successfully');
    })
    .catch((error) => {
        console.error('❌ Database connection failed:', error);
    });

// Graceful shutdown
process.on('beforeExit', async () => {
    await prisma.$disconnect();
});

export { prisma };
