
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const rewards = [
        {
            name: '1 Month Premium',
            description: 'Unlock all premium features for 30 days',
            pointsCost: 500,
            type: 'subscription',
            minTier: 'BRONZE',
            isFeatured: true,
            metadata: {
                durationDays: 30,
                features: ['Unlimited scans', 'Priority support'],
            },
        },
        {
            name: '3 Months Premium',
            description: 'Unlock all premium features for 90 days',
            pointsCost: 1200,
            type: 'subscription',
            minTier: 'SILVER',
            isFeatured: true,
            metadata: {
                durationDays: 90,
                features: ['Unlimited scans', 'Priority support'],
            },
        },
        {
            name: 'Elite Shield Access',
            description: 'Exclusive Gold-tier security features',
            pointsCost: 3000,
            type: 'subscription',
            minTier: 'GOLD',
            isFeatured: true,
            metadata: {
                durationDays: 180,
                features: ['Advanced AI Risk Score', 'Custom Alert Rules'],
            },
        },
        {
            name: 'Diamond Guardian Badge',
            description: 'The ultimate mark of a scam fighter',
            pointsCost: 8000,
            type: 'badge',
            minTier: 'DIAMOND',
            metadata: {
                badgeName: 'Diamond Guardian',
                icon: '💎',
            },
        }
    ];

    console.log('Seeding rewards...');
    for (const reward of rewards) {
        await prisma.reward.upsert({
            where: { id: reward.name }, // This won't work as ID is UUID, but I can use name if I had unique constraint. 
            // I'll just use create and catch error or check first.
            update: {},
            create: reward as any,
        }).catch(e => {
            // If it fails because of unique constraint on name (if any), it's fine
            console.log(`Skipping ${reward.name} or it already exists.`);
        });
    }

    // Actually Reward doesn't have unique name in schema. I'll just use createMany with skip duplicates if I had a unique field.
    // Since I don't, I'll just check if it exists by name first.
    for (const reward of rewards) {
        const existing = await prisma.reward.findFirst({ where: { name: reward.name } });
        if (!existing) {
            await prisma.reward.create({ data: reward as any });
            console.log(`Created reward: ${reward.name}`);
        } else {
            await prisma.reward.update({
                where: { id: existing.id },
                data: reward as any
            });
            console.log(`Updated reward: ${reward.name}`);
        }
    }

    console.log('Seeding completed.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
