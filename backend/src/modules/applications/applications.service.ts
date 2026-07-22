import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ApplicationsService {
  constructor(private readonly prisma: PrismaService) {}

  async apply(artisanUserId: string, jobId: string, data: { price: number; estimatedDuration?: string; proposal: string }) {
    const artisan = await this.prisma.artisan.findUnique({ where: { userId: artisanUserId } });
    if (!artisan) {
      throw new NotFoundException('Artisan profile not found');
    }

    const job = await this.prisma.job.findUnique({ where: { id: jobId } });
    if (!job) {
      throw new NotFoundException(`Job with ID ${jobId} not found`);
    }

    return this.prisma.jobApplication.create({
      data: {
        jobId,
        artisanId: artisan.id,
        price: data.price,
        estimatedDuration: data.estimatedDuration,
        proposal: data.proposal,
        status: 'PENDING',
      },
    });
  }

  async listForJob(jobId: string) {
    return this.prisma.jobApplication.findMany({
      where: { jobId },
      include: { artisan: true },
      orderBy: { createdAt: 'desc' },
    });
  }
}
