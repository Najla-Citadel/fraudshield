import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('🔍 Checking for potential issues in Scam Reports data...');

    const reports = await (prisma as any).scamReport.findMany({
        include: {
            user: {
                include: {
                    profile: true,
                },
            },
        },
    });

    let orphans = 0;
    let missingProfiles = 0;

    for (const report of reports) {
        if (!report.user) {
            console.error(`❌ Report ${report.id} is an orphan (no user)!`);
            orphans++;
        } else if (!report.user.profile) {
            console.warn(`⚠️ Report ${report.id} has a user (${report.user.email}) but no profile!`);
            missingProfiles++;
        }
    }

    console.log('\n--- Summary ---');
    console.log(`Total Reports: ${reports.length}`);
    console.log(`Orphaned Reports: ${orphans}`);
    console.log(`Reports with Missing Profiles: ${missingProfiles}`);

    if (orphans === 0 && missingProfiles === 0) {
        console.log('\n✅ No data integrity issues found in reports.');
    } else {
        console.log('\n🛠️ Recommended actions: Fix schemas or cleanup orphaned data.');
    }
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
