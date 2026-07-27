import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function setAdmin() {
  try {
    await prisma.user.update({
      where: { email: 'helpdesk@skillspays.com' },
      data: { role: 'ADMIN' },
    });
    console.log('Successfully updated helpdesk@skillspays.com to ADMIN');
  } catch (err) {
    console.error('Failed to update user:', err);
  }
}

setAdmin().finally(() => prisma.$disconnect());
