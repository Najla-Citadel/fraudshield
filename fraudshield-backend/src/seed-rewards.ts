import { prisma } from './config/database';

async function seedRewards() {
    console.log('🌱 Seeding rewards...');

    const rewards = [
        {
            name: '1 Month Premium',
            description: 'Unlock all premium features for 30 days',
            pointsCost: 500,
            type: 'subscription',
            metadata: {
                durationDays: 30,
                features: ['Unlimited scans', 'Priority support', 'Advanced analytics'],
            },
        },
        {
            name: '3 Months Premium',
            description: 'Unlock all premium features for 90 days',
            pointsCost: 1200,
            type: 'subscription',
            metadata: {
                durationDays: 90,
                features: ['Unlimited scans', 'Priority support', 'Advanced analytics'],
            },
        },
        {
            name: '1 Year Premium',
            description: 'Unlock all premium features for 365 days',
            pointsCost: 4000,
            type: 'subscription',
            metadata: {
                durationDays: 365,
                features: ['Unlimited scans', 'Priority support', 'Advanced analytics'],
            },
        },
        {
            name: 'Scam Hunter Badge',
            description: 'Show off your scam-fighting prowess',
            pointsCost: 300,
            type: 'badge',
            metadata: {
                badgeName: 'Scam Hunter',
                icon: '🎯',
            },
        },
        {
            name: 'Guardian Badge',
            description: 'Protect the community with pride',
            pointsCost: 200,
            type: 'badge',
            metadata: {
                badgeName: 'Guardian',
                icon: '🛡️',
            },
        },
    ];

    try {
        // Check if rewards already exist
        const existingRewards = await (prisma as any).reward.count();

        if (existingRewards > 0) {
            console.log(`⚠️  ${existingRewards} rewards already exist. Skipping seed.`);
            console.log('To re-seed, delete existing rewards first.');
            return;
        }

        // Create rewards
        const created = await (prisma as any).reward.createMany({
            data: rewards,
        });

        console.log(`✅ Successfully seeded ${created.count} rewards!`);

        // Display created rewards
        const allRewards = await (prisma as any).reward.findMany({
            orderBy: { pointsCost: 'asc' },
        });

        console.log('\n📋 Rewards Catalog:');
        allRewards.forEach((reward: any) => {
            console.log(`  - ${reward.name} (${reward.pointsCost} points) - ${reward.type}`);
        });

    } catch (error) {
        console.error('❌ Error seeding rewards:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

seedRewards()
    .then(() => {
        console.log('\n✨ Seed completed!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('Fatal error:', error);
        process.exit(1);
    });
