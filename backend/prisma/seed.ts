import { PrismaClient, Role } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // ─── Categories ─────────────────────────────────────────────────────────────
  const categories = [
    { name: 'Electrical', icon: '⚡', description: 'Electrical installations and repairs' },
    { name: 'Plumbing', icon: '🔧', description: 'Plumbing fixes and installations' },
    { name: 'Painting', icon: '🎨', description: 'Interior and exterior painting' },
    { name: 'Cleaning', icon: '🧹', description: 'Home and office cleaning services' },
    { name: 'Carpentry', icon: '🪚', description: 'Furniture and woodwork' },
    { name: 'Roofing', icon: '🏠', description: 'Roof repairs and installations' },
    { name: 'Generator Repair', icon: '⚙️', description: 'Generator servicing and repairs' },
    { name: 'AC Repair', icon: '❄️', description: 'Air conditioning installation and repair' },
    { name: 'POP Ceiling', icon: '🏗️', description: 'POP and false ceiling installations' },
    { name: 'Furniture', icon: '🪑', description: 'Furniture assembly and repairs' },
  ];

  for (const cat of categories) {
    await prisma.category.upsert({
      where: { name: cat.name },
      update: {},
      create: cat,
    });
  }
  console.log(`✅ ${categories.length} categories seeded`);

  console.log('✅ Seeding complete');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
