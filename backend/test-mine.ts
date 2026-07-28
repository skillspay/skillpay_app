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
  const artisanId = 'ec9fea4b-b53f-4374-be45-6ff54df95f13';
  const bookings = await prisma.booking.findMany({
    where: {
      artisanId,
      status: { in: ['CONFIRMED', 'IN_PROGRESS'] },
    },
    include: BOOKING_INCLUDE,
    orderBy: { createdAt: 'desc' },
  });
  console.dir(bookings, { depth: null });
}

main().catch(console.error).finally(() => prisma.$disconnect());
