const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const booking = await prisma.booking.findFirst({
    where: { jobId: 'fdc8727a-b45b-424f-bd3d-a38a5b20dd18' },
    include: { homeowner: true }
  });
  console.log('Booking:', booking);
}
main().catch(console.error).finally(() => prisma.$disconnect());
