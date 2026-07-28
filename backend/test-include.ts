import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

const BOOKING_INCLUDE = {
  job: {
    select: {
      id: true,
      title: true,
      description: true,
      timeline: true,
      preferredDate: true,
      category: { select: { id: true, name: true } },
    },
  },
  application: { select: { id: true, price: true, proposal: true } },
  artisan: { select: { id: true, fullName: true, profilePhoto: true } },
  homeowner: { select: { id: true, fullName: true, profilePhoto: true } },
  payment: true,
};

async function main() {
  const id = '5123610c-4171-4142-9819-d39627e397a7';
  
  const result = await prisma.$transaction(async (tx) => {
    return tx.booking.update({
      where: { id },
      data: { status: 'COMPLETED' },
      include: BOOKING_INCLUDE,
    });
  });
  console.log('Result:', result.id);
}

main().catch(console.error).finally(() => prisma.$disconnect());
