import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const id = '5123610c-4171-4142-9819-d39627e397a7';
  const booking = await prisma.booking.findUnique({ 
    where: { id },
    include: {
      application: true,
      job: true,
      artisan: true,
      homeowner: true,
    },
  });
  console.log('Booking:', booking);
  
  if (!booking) return console.log('not found');

  const result = await prisma.$transaction(async (tx) => {
    await tx.job.update({
      where: { id: booking.jobId },
      data: { status: 'COMPLETED' },
    });

    return tx.booking.update({
      where: { id },
      data: { status: 'COMPLETED', completionDate: new Date() },
    });
  });
  console.log('Result:', result);
}

main().catch(console.error).finally(() => prisma.$disconnect());
