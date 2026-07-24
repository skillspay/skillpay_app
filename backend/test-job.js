const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const homeowner = await prisma.homeowner.findFirst();
  if (!homeowner) return console.log('No homeowner found');

  const { JobsService } = require('./dist/modules/jobs/jobs.service.js');
  const { AiMatchService } = require('./dist/modules/jobs/ai-match.service.js');
  
  const aiMatchService = new AiMatchService(prisma);
  const jobsService = new JobsService(prisma, aiMatchService);

  console.log('Creating job...');
  const job = await jobsService.create(homeowner.userId, {
    title: 'Fix my sink',
    description: 'Leaking pipe under sink',
    budget: 150,
    address: 'San Francisco, CA',
  });

  console.log('Job created, waiting for AI Match...');
  await new Promise(r => setTimeout(r, 2000));
}
main().catch(console.error).finally(() => prisma.$disconnect());
