const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const jobs = await prisma.job.findMany({
    take: 5,
    orderBy: { createdAt: 'desc' }
  });
  console.log('Recent jobs:');
  jobs.forEach(j => console.log(j.id, j.title, 'Budget:', j.budget));
  
  const bookings = await prisma.booking.findMany({
    take: 5,
    orderBy: { createdAt: 'desc' },
    include: {
      application: true,
      job: true
    }
  });
  console.log('\nRecent bookings:');
  bookings.forEach(b => console.log(b.id, 'App price:', b.application?.price, 'Job budget:', b.job?.budget));
}
main().catch(console.error).finally(() => prisma.$disconnect());
