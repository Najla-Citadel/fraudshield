import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function seedAdmin() {
    const email = 'admin@fraudshield.com';
    const password = 'AdminPassword123';
    
    console.log(`--- Seeding Admin User: ${email} ---`);
    
    try {
        const passwordHash = await bcrypt.hash(password, 10);
        
        const admin = await prisma.user.upsert({
            where: { email },
            update: {
                role: 'admin',
                passwordHash,
                emailVerified: true,
                acceptedTermsAt: new Date(),
                acceptedTermsVersion: 'v1.0'
            },
            create: {
                email,
                passwordHash,
                fullName: 'System Administrator',
                role: 'admin',
                emailVerified: true,
                acceptedTermsAt: new Date(),
                acceptedTermsVersion: 'v1.0'
            }
        });

        // Ensure profile exists for points tracking
        await prisma.profile.upsert({
            where: { userId: admin.id },
            update: {},
            create: {
                userId: admin.id,
                points: 0,
                totalPoints: 0
            }
        });

        console.log('\n✓ Admin user created successfully!');
        console.log(`Email: ${email}`);
        console.log(`Password: ${password}`);
        console.log('\nYou can now log in to the Admin Dashboard.');
    } catch (error) {
        console.error('\n✗ Seeding failed:');
        console.error(error);
    } finally {
        await prisma.$disconnect();
    }
}

seedAdmin();
