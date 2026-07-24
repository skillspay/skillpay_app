const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const user = await prisma.user.findFirst({ where: { email: 'roqueverse@gmail.com' } });
  const addrs = await prisma.address.findMany({ where: { userId: user.id } });
  console.log(addrs);
}
main().catch(console.error).finally(() => prisma.$disconnect());
