import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function migrate() {
  const homeowners = await prisma.homeowner.findMany({
    where: { defaultAddress: { not: null } }
  });

  console.log(`Found ${homeowners.length} homeowners with defaultAddress`);

  for (const h of homeowners) {
    if (!h.defaultAddress) continue;
    
    const count = await prisma.address.count({ where: { userId: h.userId } });
    if (count === 0) {
      await prisma.address.create({
        data: {
          userId: h.userId,
          label: 'Home',
          address: h.defaultAddress,
          latitude: h.latitude,
          longitude: h.longitude,
          isDefault: true,
        }
      });
      console.log(`Created address for user ${h.userId}`);
    } else {
      console.log(`User ${h.userId} already has addresses`);
    }
  }

  console.log('Migration complete.');
}

migrate().catch(console.error).finally(() => prisma.$disconnect());
