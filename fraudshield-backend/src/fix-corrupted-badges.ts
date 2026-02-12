import { prisma } from './config/database';

async function fixBadges() {
    console.log('🧹 Starting badge cleanup...');

    try {
        const profiles = await (prisma as any).profile.findMany();
        console.log(`🔍 Checking ${profiles.length} profiles...`);

        for (const profile of profiles) {
            let badges = profile.badges;
            let needsUpdate = false;

            // Handle stringified JSON in DB
            if (typeof badges === 'string') {
                try {
                    badges = JSON.parse(badges);
                    needsUpdate = true; // Mark for update to save as proper Json
                } catch (e) {
                    console.error(`❌ Could not parse badges for user ${profile.userId}`);
                    continue;
                }
            }

            if (Array.isArray(badges)) {
                // Check if this looks like a corrupted array (many single-character strings)
                if (badges.length > 3) { // A legit mix wouldn't typically have many single-char entries in a row
                    const charCount = badges.filter(b => typeof b === 'string' && b.length === 1).length;

                    if (charCount > 5) { // More than 5 single chars is a strong indicator of string-splitting
                        console.log(`⚠️ Found corrupted badges for user ${profile.userId}: ${JSON.stringify(badges)}`);

                        let reconstructed = '';
                        let properBadges: string[] = [];

                        for (const b of badges) {
                            if (typeof b === 'string' && b.length === 1) {
                                reconstructed += b;
                            } else if (typeof b === 'string' && b.length > 1) {
                                properBadges.push(b);
                            }
                        }

                        // Check if reconstructed string looks like a JSON list
                        if (reconstructed.includes('[') && reconstructed.includes(']')) {
                            const match = reconstructed.match(/\[.*\]/);
                            if (match) {
                                try {
                                    const parsed = JSON.parse(match[0]);
                                    if (Array.isArray(parsed)) {
                                        properBadges = [...properBadges, ...parsed];
                                    } else if (typeof parsed === 'string') {
                                        properBadges.push(parsed);
                                    }
                                } catch (e) {
                                    console.log(`   - Partial reconstruction: ${reconstructed}`);
                                }
                            }
                        }

                        // De-duplicate and clean up any empty strings
                        const finalBadges = Array.from(new Set(properBadges)).filter(b => b.length > 0);

                        console.log(`✅ Fixed badges: ${JSON.stringify(finalBadges)}`);

                        await (prisma as any).profile.update({
                            where: { id: profile.id },
                            data: { badges: finalBadges }
                        });
                        continue;
                    }
                }
            }

            if (needsUpdate) {
                await (prisma as any).profile.update({
                    where: { id: profile.id },
                    data: { badges: badges }
                });
            }
        }

        console.log('✨ Cleanup complete!');
    } catch (error) {
        console.error('❌ Error during cleanup:', error);
    } finally {
        await prisma.$disconnect();
    }
}

fixBadges();
