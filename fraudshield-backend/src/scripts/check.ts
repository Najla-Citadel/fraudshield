import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
prisma.alertSubscription.findFirst().then(s => console.log(JSON.stringify(s, null, 2))).finally(() => prisma.$disconnect());
