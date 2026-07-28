const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  await prisma.$executeRawUnsafe(`ALTER PUBLICATION supabase_realtime ADD TABLE messages;`);
  console.log('Realtime enabled for messages');
}
main().catch(console.error).finally(() => prisma.$disconnect());
