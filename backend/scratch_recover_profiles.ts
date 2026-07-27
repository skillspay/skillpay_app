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

async function recoverProfiles() {
  console.log('Fetching users from Supabase...');
  const { data: { users }, error } = await supabase.auth.admin.listUsers();
  if (error) {
    console.error('Error fetching users:', error);
    return;
  }

  for (const user of users) {
    if (!user.email) continue;
    
    const dbUser = await prisma.user.findUnique({ where: { email: user.email } });
    if (!dbUser) continue; // Should exist

    // Fallback to the first part of their email if no name is found in metadata
    const fullName = user.user_metadata?.full_name || user.user_metadata?.fullName || user.email.split('@')[0];

    if (dbUser.role === Role.HOMEOWNER || dbUser.role === Role.ADMIN) {
      const existingHomeowner = await prisma.homeowner.findUnique({ where: { userId: dbUser.id } });
      if (!existingHomeowner) {
        console.log(`Creating Homeowner profile for ${dbUser.email} with name ${fullName}`);
        await prisma.homeowner.create({
          data: {
            userId: dbUser.id,
            fullName: fullName,
          }
        });
      }
    } else if (dbUser.role === Role.ARTISAN) {
      const existingArtisan = await prisma.artisan.findUnique({ where: { userId: dbUser.id } });
      if (!existingArtisan) {
        console.log(`Creating Artisan profile for ${dbUser.email} with name ${fullName}`);
        await prisma.artisan.create({
          data: {
            userId: dbUser.id,
            fullName: fullName,
          }
        });
      }
    }
  }
  
  console.log('Profile recovery finished successfully!');
}

recoverProfiles().catch(console.error).finally(() => prisma.$disconnect());
