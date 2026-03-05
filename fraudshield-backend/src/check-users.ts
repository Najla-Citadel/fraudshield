
import { prisma } from './config/database';

async function checkUsers() {
    console.log('🔍 Checking Users in DB...');
    const users = await prisma.user.findMany({
        take: 10,
        select: {
            email: true,
            emailVerified: true
        }
    });

    console.log('Recent Users:');
    users.forEach(u => console.log(`- ${u.email} (Verified: ${u.emailVerified})`));
}

checkUsers().catch(console.error).finally(() => prisma.$disconnect());
