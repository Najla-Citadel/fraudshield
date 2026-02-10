import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Seeding database...');

    // Create a system user for the reports
    const systemUser = await prisma.user.upsert({
        where: { email: 'system@fraudshield.com' },
        update: {},
        create: {
            email: 'system@fraudshield.com',
            passwordHash: '$2b$10$K7L1AOBzpaXfR/X/D.M16uXpXg.p.S.xM.z.z.z.z.z.z.z.z.z.z', // Dummy hash
            fullName: 'System Defender',
        },
    });

    const reports = [
        {
            type: 'Phone',
            category: 'Phishing Scam',
            target: '+60123456789',
            description: 'Received a call claiming to be from the Tax Department asking for banking details.',
            userId: systemUser.id,
            isPublic: true,
            latitude: 3.1478,
            longitude: 101.6940, // KL Sentral area
        },
        {
            type: 'Message',
            category: 'Investment Scam',
            target: 'bit.ly/fake-invest',
            description: 'WhatsApp message promising 500% returns in 2 hours. Stay away!',
            userId: systemUser.id,
            isPublic: true,
            latitude: 3.1578,
            longitude: 101.7123, // KLCC area
        },
        {
            type: 'Message',
            category: 'Job Scam',
            target: 'HR-Global-Jobs',
            description: 'Part-time job offer for RM300/day just for clicking links. Requires RM50 deposit.',
            userId: systemUser.id,
            isPublic: true,
            latitude: 3.1230,
            longitude: 101.6730, // Mid Valley area
        },
    ];

    for (const report of reports) {
        await prisma.scamReport.create({
            data: report,
        });
    }

    console.log('Seed completed successfully!');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
