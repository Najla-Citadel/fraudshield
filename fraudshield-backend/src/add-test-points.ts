import { prisma } from './config/database';

async function giveUserPoints() {
    console.log('💰 Adding points to user...');

    try {
        // Target the specific user from the screenshot
        const targetUserId = '293f6319-70d5-4107-8380-8051f6f5e031';

        const user = await (prisma as any).user.findUnique({
            where: { id: targetUserId },
            include: { profile: true },
        });

        if (!user) {
            console.error('❌ User not found');
            return;
        }

        console.log(`\n👤 User: ${user.email}`);
        console.log(`📊 Current points: ${user.profile?.points || 0}`);

        // Add 5000 points for testing as requested
        const pointsToAdd = 5000;

        await (prisma as any).profile.update({
            where: { userId: user.id },
            data: { points: { increment: pointsToAdd } },
        });

        await (prisma as any).pointsTransaction.create({
            data: {
                userId: user.id,
                amount: pointsToAdd,
                description: 'Testing bonus - for redemption testing',
            },
        });

        const updatedProfile = await (prisma as any).profile.findUnique({
            where: { userId: user.id },
        });

        console.log(`✅ Added ${pointsToAdd} points!`);
        console.log(`📊 New balance: ${updatedProfile.points} points`);
        console.log('\n🎯 You can now test redemption with:');
        console.log('  - Guardian Badge (200 points)');
        console.log('  - Scam Hunter Badge (300 points)');
        console.log('  - 1 Month Premium (500 points)');

    } catch (error) {
        console.error('❌ Error adding points:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

giveUserPoints()
    .then(() => {
        console.log('\n✨ Done!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('Fatal error:', error);
        process.exit(1);
    });
