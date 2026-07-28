import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  const id = '75714daf-4d1e-4226-b521-3020655a7b48'; // Booking ID from previous output
  const customerUserId = 'unknown'; // I don't know the user's ID
  
  const booking = await prisma.booking.findUnique({
    where: { id },
    include: {
      application: true,
      job: true,
      artisan: true,
      homeowner: true,
    },
  });

  if (!booking) {
    console.log('Error: Booking not found');
    return;
  }
  
  console.log('Booking homeowner userId:', booking.homeowner.userId);
  console.log('Booking status:', booking.status);

}

main().catch(console.error).finally(() => process.exit(0));
