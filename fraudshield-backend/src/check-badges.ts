import { prisma } from './config/database';

async function checkBadges() {
    try {
        const profiles = await (prisma as any).profile.findMany({
            include: { user: true }
        });

        for (const p of profiles) {
            console.log(`User: ${p.user.email} (${p.userId})`);
            console.log(`Badges: ${JSON.stringify(p.badges)} (Type: ${typeof p.badges})`);
            if (Array.isArray(p.badges)) {
                console.log(`Is Array: Yes, Length: ${p.badges.length}`);
            }
            console.log('---');
        }
    } catch (e) {
        console.error(e);
    } finally {
        await prisma.$disconnect();
    }
}

checkBadges();
