import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('🚨 Injecting a simulated high-severity E-Commerce trend...');

    // Find the system user
    const user = await prisma.user.findFirst({
        where: { email: 'system@fraudshield.com' }
    });

    if (!user) {
        console.error('System user not found, run db seed first.');
        return;
    }

    // Insert 10 reports to trigger 'high' severity
    for (let i = 0; i < 10; i++) {
        await prisma.scamReport.create({
            data: {
                type: 'Message',
                category: 'E-Commerce Scam',
                target: `fake-shop-${i}.com`,
                description: `Fake online store taking payments but never delivering goods: fake-shop-${i}.com`,
                userId: user.id,
                isPublic: true,
                latitude: 3.1478 + (Math.random() * 0.01),
                longitude: 101.6940 + (Math.random() * 0.01),
            }
        });
    }

    console.log('✅ Injected 10 new E-Commerce Scam reports into the database.');
    console.log('⏳ The Alert Engine (cron job) should pick this up within 60 seconds and trigger a Push Notification!');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
