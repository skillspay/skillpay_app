import { Module } from '@nestjs/common';
import { JobsService } from './jobs.service';
import { JobsController } from './jobs.controller';
import { AiMatchService } from './ai-match.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [JobsController],
  providers: [JobsService, AiMatchService],
  exports: [JobsService],
})
export class JobsModule {}
