import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function clearDatabase() {
  console.log('--- Database Cleanup Started ---');
  
  const tables = [
    'Verification',
    'Comment',
    'ScamReport',
    'PointsTransaction',
    'Alert',
    'Transaction',
    'FraudLabel',
    'Redemption',
    'Reward',
    'SecurityScan',
    'AppActionLog',
    'AppReputation',
    'BehavioralEvent',
    'AlertSubscription',
    'TransactionJournal',
    'UserSubscription',
    'SubscriptionPlan',
    'Profile',
    'AuditLog',
    'BadgeDefinition',
    'User',
  ];

  try {
    // For PostgreSQL, we can use TRUNCATE with CASCADE to handle foreign keys automatically
    // We execute them in a specific order just to be safe, or use a bulk command
    console.log(`Clearing ${tables.length} tables...`);
    
    for (const table of tables) {
      await prisma.$executeRawUnsafe(`TRUNCATE TABLE "${table}" CASCADE;`);
      console.log(`  ✓ Cleared ${table}`);
    }

    console.log('\n--- Database Cleanup Successful ---');
    console.log('All data has been wiped. Indexes and schemas remain intact.');
  } catch (error) {
    console.error('\n--- Database Cleanup Failed ---');
    console.error(error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

clearDatabase();
