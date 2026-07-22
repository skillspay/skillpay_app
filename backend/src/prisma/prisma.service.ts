import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  constructor() {
    super({
      log: [
        { emit: 'event', level: 'query' },
        { emit: 'stdout', level: 'error' },
        { emit: 'stdout', level: 'warn' },
      ],
    });
  }

  async onModuleInit() {
    await this.$connect();
    this.logger.log('✅ Prisma connected to database');
  }

  async onModuleDestroy() {
    await this.$disconnect();
    this.logger.log('Prisma disconnected from database');
  }

  /** Helper for soft-delete / pagination use cases */
  async cleanDatabase() {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('cleanDatabase is not allowed in production');
    }
    // Order matters due to FK constraints
    await this.adminLog.deleteMany();
    await this.verificationDocument.deleteMany();
    await this.report.deleteMany();
    await this.notification.deleteMany();
    await this.walletTransaction.deleteMany();
    await this.wallet.deleteMany();
    await this.payment.deleteMany();
    await this.review.deleteMany();
    await this.message.deleteMany();
    await this.conversation.deleteMany();
    await this.booking.deleteMany();
    await this.jobApplication.deleteMany();
    await this.job.deleteMany();
    await this.address.deleteMany();
    await this.artisanCategory.deleteMany();
    await this.category.deleteMany();
    await this.artisan.deleteMany();
    await this.homeowner.deleteMany();
    await this.user.deleteMany();
  }
}
