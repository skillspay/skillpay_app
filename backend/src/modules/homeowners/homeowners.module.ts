import { Module } from '@nestjs/common';
import { HomeownersService } from './homeowners.service';
import { HomeownersController } from './homeowners.controller';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [HomeownersController],
  providers: [HomeownersService],
  exports: [HomeownersService],
})
export class HomeownersModule {}
