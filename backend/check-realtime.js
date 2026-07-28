const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const result = await prisma.$queryRaw`
    SELECT pubname, tablename
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime';
  `;
  console.log('Realtime tables:', result);
}
main().catch(console.error).finally(() => prisma.$disconnect());
