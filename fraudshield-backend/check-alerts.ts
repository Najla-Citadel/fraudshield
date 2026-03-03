import { prisma } from './src/config/database';

async function checkAlerts() {
    try {
        const users = await prisma.user.findMany({
            include: {
                _count: {
                    select: { alerts: true }
                }
            }
        });

        console.log('--- User Alert Status ---');
        users.forEach(u => {
            console.log(`User: ${u.email} | Alerts: ${u._count.alerts}`);
        });

        const recentAlerts = await prisma.alert.findMany({
            take: 10,
            orderBy: { createdAt: 'desc' }
        });

        console.log('\n--- Recent Alerts ---');
        recentAlerts.forEach(a => {
            console.log(`[${a.createdAt.toISOString()}] ${a.title}: ${a.message} (User: ${a.userId})`);
        });

    } catch (error) {
        console.error('Error checking alerts:', error);
    } finally {
        await prisma.$disconnect();
    }
}

checkAlerts();
