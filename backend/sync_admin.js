const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Fetching users from Supabase auth.users...');
  
  try {
    // We can query the Supabase auth schema directly using raw SQL
    const authUsers = await prisma.$queryRaw`SELECT id, email FROM auth.users`;
    
    if (!authUsers || authUsers.length === 0) {
      console.log('No users found in Supabase Auth. Please create one in the dashboard first.');
      return;
    }

    console.log(`Found ${authUsers.length} user(s) in Supabase.`);

    for (const user of authUsers) {
      // Check if they already exist in our public.User table
      const existing = await prisma.user.findUnique({
        where: { supabaseUserId: user.id },
      });

      if (!existing) {
        console.log(`Adding ${user.email} to Prisma User table as SUPER_ADMIN...`);
        await prisma.user.create({
          data: {
            supabaseUserId: user.id,
            email: user.email,
            role: 'SUPER_ADMIN',
            isVerified: true,
          },
        });
        console.log(`✅ Success! ${user.email} is now a SUPER_ADMIN.`);
      } else {
        console.log(`User ${user.email} already exists in the Prisma User table.`);
        if (existing.role !== 'SUPER_ADMIN') {
          console.log(`Upgrading ${user.email} to SUPER_ADMIN...`);
          await prisma.user.update({
            where: { id: existing.id },
            data: { role: 'SUPER_ADMIN', isVerified: true }
          });
          console.log(`✅ Upgraded ${user.email}.`);
        }
      }
    }
  } catch (error) {
    console.error('Error syncing users:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
