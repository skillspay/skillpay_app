import { PrismaClient, Role } from '@prisma/client';
import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
import { join } from 'path';

dotenv.config({ path: join(__dirname, '.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);
const prisma = new PrismaClient();

async function recover() {
  console.log('Fetching users from Supabase...');
  const { data: { users }, error } = await supabase.auth.admin.listUsers();
  if (error) {
    console.error('Error fetching users:', error);
    return;
  }

  console.log(`Found ${users.length} users in Supabase Auth.`);

  for (const user of users) {
    if (!user.email) continue;
    
    // Check if user already exists
    const existing = await prisma.user.findUnique({ where: { supabaseUserId: user.id } });
    if (existing) {
      console.log(`User ${user.email} already exists in database. Skipping.`);
      continue;
    }

    // Determine role from metadata if available
    const roleString = user.user_metadata?.role;
    let role: Role = Role.HOMEOWNER;
    if (roleString === 'ARTISAN' || roleString === 'artisan') role = Role.ARTISAN;
    if (roleString === 'ADMIN' || roleString === 'admin') role = Role.ADMIN;

    console.log(`Restoring ${user.email} as ${role}...`);
    
    await prisma.user.create({
      data: {
        supabaseUserId: user.id,
        email: user.email,
        role: role,
        phone: user.phone || null,
        isVerified: true,
      }
    });
  }
  
  console.log('Recovery finished successfully!');
}

recover().catch(console.error).finally(() => prisma.$disconnect());
