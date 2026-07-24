import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function seed() {
  const user = await prisma.user.findFirst({
    where: { email: { startsWith: 'damicoledj' } }
  });

  if (!user) {
    console.log('User not found');
    return;
  }

  const artisan = await prisma.artisan.findFirst({
    where: { userId: user.id }
  });

  if (!artisan) {
    console.log('Artisan not found');
    return;
  }

  console.log('Found artisan', artisan.id);

  await prisma.artisan.update({
    where: { id: artisan.id },
    data: {
      coverLetter: "Hi! I am Damilola. I have over 5 years of experience delivering top quality work. I specialize in plumbing and general repairs.",
    }
  });

  await prisma.artisanPost.create({
    data: {
      artisanId: artisan.id,
      title: "Fixed a leak in Lekki",
      description: "Complete pipe replacement and leak fix.",
      imageUrl: "https://images.unsplash.com/photo-1585704032915-c3400ca199e7?q=80&w=2070&auto=format&fit=crop",
    }
  });

  console.log('Seeded cover letter and post successfully.');
}

seed().catch(console.error).finally(() => prisma.$disconnect());
