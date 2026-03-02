import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const email = 'xxjiaqianxx@gmail.com';
    console.log(`🚀 Seeding mock reports for user: ${email}`);

    // 1. Find the user
    const user = await prisma.user.findUnique({
        where: { email },
    });

    if (!user) {
        console.error(`❌ User with email ${email} not found! Please make sure the account is created.`);
        process.exit(1);
    }

    const userId = user.id;

    // 2. Mock Reports Data
    const mockReports = [
        {
            type: 'Phone',
            target: '+6012-3456789',
            targetType: 'phone',
            description: 'Received a suspicious call claiming to be from a local bank regarding an urgent account issue.',
            category: 'Bank Impersonation',
            status: 'VERIFIED',
            isPublic: true,
        },
        {
            type: 'Message',
            target: 'http://secure-login-bank.com',
            targetType: 'url',
            description: 'Phishing SMS with a link asking to update account details immediately.',
            category: 'Phishing',
            status: 'PENDING',
            isPublic: false,
        },
        {
            type: 'Message',
            target: '+6011-98765432',
            targetType: 'phone',
            description: 'WhatsApp message offering high-return investment opportunities with "guaranteed" profits.',
            category: 'Investment Scam',
            status: 'PENDING',
            isPublic: true,
        },
        {
            type: 'Document',
            target: 'fake_invoice_2024.pdf',
            targetType: 'doc',
            description: 'Received a fake invoice via email for a service never rendered.',
            category: 'Invoice Fraud',
            status: 'REJECTED',
            isPublic: false,
        },
        {
            type: 'Phone',
            target: '+603-22114455',
            targetType: 'phone',
            description: 'Automated call claiming a parcel from a courier service is being held for tax payment.',
            category: 'Courier Scam',
            status: 'VERIFIED',
            isPublic: true,
        },
    ];

    console.log(`Adding ${mockReports.length} reports...`);

    for (const data of mockReports) {
        await (prisma as any).scamReport.create({
            data: {
                ...data,
                userId,
                evidence: {},
            },
        });
    }

    console.log('✅ Mock reports seeded successfully!');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
