import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function seedUserReports() {
    const email = 'xxjiaqianxx@gmail.com';
    const password = 'UserPassword123';
    
    console.log(`--- Seeding Reports for User: ${email} ---`);
    
    try {
        const passwordHash = await bcrypt.hash(password, 10);
        
        // 1. Ensure User exists
        const user = await prisma.user.upsert({
            where: { email },
            update: {},
            create: {
                email,
                passwordHash,
                fullName: 'Jia Qian',
                role: 'user',
                emailVerified: true,
                acceptedTermsAt: new Date(),
                acceptedTermsVersion: 'v1.0'
            }
        });

        // 2. Ensure Profile exists
        await prisma.profile.upsert({
            where: { userId: user.id },
            update: {},
            create: {
                userId: user.id,
                points: 100,
                totalPoints: 100
            }
        });

        // 3. Create two Scam Reports
        const reports = [
            {
                type: 'Phone',
                category: 'Phone Scam',
                target: '+60178889999',
                targetType: 'PHONE',
                description: 'Suspected Macau Scam caller pretending to be a bank officer. Very aggressive.',
                userId: user.id,
                status: 'pending',
                isPublic: true,
                latitude: 3.1390,
                longitude: 101.6869,
                evidence: {
                    callDuration: '2m 30s',
                    callerName: 'PDRM Officer Ibrahim'
                }
            },
            {
                type: 'URL',
                category: 'Phishing',
                target: 'https://secure-maybank2u-login.com',
                targetType: 'URL',
                description: 'Fake banking login page received via SMS. Looks very realistic.',
                userId: user.id,
                status: 'pending',
                isPublic: true,
                latitude: 3.1478,
                longitude: 101.6940,
                evidence: {
                    smsContent: 'Your account has been locked. Verify here: https://secure-maybank2u-login.com'
                }
            }
        ];

        console.log('Creating reports...');
        for (const report of reports) {
            const created = await prisma.scamReport.create({
                data: report
            });
            console.log(`  ✓ Created report: ${created.id} (${created.category})`);
        }

        console.log('\n--- Seeding Successful ---');
        console.log(`User: ${email}`);
        console.log(`Reports created: ${reports.length}`);
    } catch (error) {
        console.error('\n✗ Seeding failed:');
        console.error(error);
    } finally {
        await prisma.$disconnect();
    }
}

seedUserReports();
