import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const args = process.argv.slice(2);
    if (args.length === 0) {
        console.error('❌ Please provide a User ID or Email as an argument.');
        console.error('Usage: ts-node seed-alerts.ts <email-or-id>');
        process.exit(1);
    }

    const identifier = args[0];

    // Find the user
    console.log(`🔍 Looking for user with identifier: ${identifier}`);
    const user = await prisma.user.findFirst({
        where: {
            OR: [
                { email: identifier },
                { id: identifier }
            ]
        }
    });

    if (!user) {
        console.error(`❌ User not found! Check the email or ID: ${identifier}`);
        process.exit(1);
    }

    console.log(`✅ Found user: ${user.email} (ID: ${user.id})`);

    // Optional: Ask for confirmation or just clear existing
    console.log('🧹 Clearing existing alerts for this user...');
    await prisma.alert.deleteMany({ where: { userId: user.id } });

    console.log('🌱 Seeding new demo alerts...');
    
    const now = new Date();
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);

    // 1. Suspicious Login Attempt (TODAY, 2m ago)
    await prisma.alert.create({
        data: {
            userId: user.id,
            category: 'LOGIN',
            severity: 'HIGH',
            title: 'Suspicious Login Attempt',
            message: 'A login attempt was detected from a new device in Berlin, Germany. Was this you?',
            metadata: { device: 'Chrome on Linux', location: 'Berlin, DE' }
        }
    });

    // 2. New Scam Trend: AI Voice (TODAY, 1h ago)
    await prisma.alert.create({
        data: {
            userId: user.id,
            category: 'COMMUNITY',
            severity: 'MEDIUM',
            title: 'New Scam Trend: AI Voice',
            message: 'Scammers are using AI to mimic family voices. Learn how to verify callers instantly.',
        }
    });

    // 3. System Update Successful (TODAY, 3h ago)
    await prisma.alert.create({
        data: {
            userId: user.id,
            category: 'SYSTEM_SCAN',
            severity: 'LOW',
            title: 'System Update Successful',
            message: 'FraudShield database v4.2.0 installed. Your protection is up to date.',
        }
    });

    // 4. Weekly Security Report (YESTERDAY, 1d ago)
    await prisma.alert.create({
        data: {
            userId: user.id,
            category: 'SYSTEM_SCAN',
            severity: 'LOW',
            title: 'Weekly Security Report',
            message: "You've blocked 12 suspicious links and 3 spam calls this week. Keep it up!",
            createdAt: yesterday,
        }
    });

    // 5. Gold Tier Benefit (YESTERDAY, 1d ago)
    await prisma.alert.create({
        data: {
            userId: user.id,
            category: 'COMMUNITY',
            severity: 'LOW',
            title: 'Gold Tier Benefit',
            message: 'New AI File Scanner is now available for your Gold account.',
            createdAt: yesterday,
        }
    });

    console.log('🎉 Successfully seeded 5 realistic demo alerts!');
}

main()
    .catch((e) => {
        console.error('❌ Error seeding data:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
