import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    const email = 'fang4@test.com';
    const password = 'AdminPassword123';
    const fullName = 'Fang Admin';

    console.log(`🚀 Seeding admin user: ${email}...`);

    // 1. Hash the password
    const passwordHash = await bcrypt.hash(password, 10);

    // 2. Upsert the User
    const user = await prisma.user.upsert({
        where: { email },
        update: {
            role: 'admin',
            passwordHash,
            fullName,
            emailVerified: true,
        },
        create: {
            email,
            passwordHash,
            fullName,
            role: 'admin',
            emailVerified: true,
            profile: {
                create: {
                    avatar: 'Felix',
                    bio: 'System Administrator',
                    metadata: {
                        isSeed: true
                    }
                }
            }
        },
    });

    console.log('✅ Admin user seeded successfully!');
    console.log('-----------------------------------');
    console.log(`Email:    ${email}`);
    console.log(`Password: ${password}`);
    console.log(`Role:     ${user.role}`);
    console.log('-----------------------------------');
    console.log('You can now log in to the admin dashboard.');
}

main()
    .catch((e) => {
        console.error('❌ Seeding failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
