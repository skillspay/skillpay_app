import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  
  const jobId = '04460a91-b091-4e58-8173-5e8e117a4d76';
  const job = await prisma.job.findUnique({
    where: { id: jobId },
    include: {
      booking: true,
      applications: true
    }
  });
  
  console.log('Job:', JSON.stringify(job, null, 2));

  // Also query bookings where budget is 25
  const bookings25 = await prisma.booking.findMany({
    include: { job: true, application: true },
    where: { job: { budget: 25 } }
  });
  console.log('Bookings with budget 25:', bookings25.length);
}

main().catch(console.error).finally(() => process.exit(0));
