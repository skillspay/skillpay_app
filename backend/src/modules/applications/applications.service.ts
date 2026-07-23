import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

const APPLICATION_INCLUDE = {
  artisan: {
    select: {
      id: true,
      fullName: true,
      profilePhoto: true,
      bio: true,
      averageRating: true,
      completedJobs: true,
      hourlyRate: true,
      categories: { include: { category: true } },
    },
  },
  job: {
    select: {
      id: true,
      title: true,
      address: true,
      budget: true,
      status: true,
      category: { select: { id: true, name: true } },
    },
  },
};

@Injectable()
export class ApplicationsService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── Submit application (artisan) ─────────────────────────────────────────

  async apply(
    userId: string,
    jobId: string,
    data: { price: number; estimatedDuration?: string; proposal: string },
  ) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { userId },
    });
    if (!artisan) throw new NotFoundException('Artisan profile not found');

    const job = await this.prisma.job.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundException(`Job ${jobId} not found`);

    return this.prisma.jobApplication.create({
      data: {
        jobId,
        artisanId: artisan.id,
        price: data.price,
        estimatedDuration: data.estimatedDuration,
        proposal: data.proposal,
        status: 'PENDING',
      },
      include: APPLICATION_INCLUDE,
    });
  }

  // ─── List for homeowner's jobs ─────────────────────────────────────────────

  async listForHomeowner(
    userId: string,
    status?: string,
    jobId?: string,
  ) {
    const homeowner = await this.prisma.homeowner.findUnique({
      where: { userId },
    });
    if (!homeowner) return [];

    return this.prisma.jobApplication.findMany({
      where: {
        job: { homeownerId: homeowner.id },
        ...(status ? { status: status as any } : {}),
        ...(jobId ? { jobId } : {}),
      },
      include: APPLICATION_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
  }

  // ─── List artisan's own applications ─────────────────────────────────────

  async listForArtisan(userId: string, status?: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { userId },
    });
    if (!artisan) return [];

    return this.prisma.jobApplication.findMany({
      where: {
        artisanId: artisan.id,
        ...(status ? { status: status as any } : {}),
      },
      include: APPLICATION_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
  }

  // ─── Jobs the artisan applied to ─────────────────────────────────────────

  async jobsAppliedTo(userId: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { userId },
    });
    if (!artisan) return [];

    const applications = await this.prisma.jobApplication.findMany({
      where: {
        artisanId: artisan.id,
        status: { in: ['PENDING', 'ACCEPTED'] },
      },
      include: {
        job: {
          include: {
            category: { select: { id: true, name: true } },
            homeowner: { select: { id: true, fullName: true, profilePhoto: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return applications.map((a) => a.job);
  }

  // ─── Single application ───────────────────────────────────────────────────

  async findOne(id: string) {
    const app = await this.prisma.jobApplication.findUnique({
      where: { id },
      include: APPLICATION_INCLUDE,
    });
    if (!app) throw new NotFoundException(`Application ${id} not found`);
    return app;
  }

  // ─── Accept (homeowner) ───────────────────────────────────────────────────

  async accept(userId: string, applicationId: string) {
    const homeowner = await this.prisma.homeowner.findUnique({
      where: { userId },
    });
    if (!homeowner) throw new NotFoundException('Homeowner not found');

    const app = await this.prisma.jobApplication.findUnique({
      where: { id: applicationId },
      include: { job: true },
    });
    if (!app) throw new NotFoundException(`Application ${applicationId} not found`);
    if (app.job.homeownerId !== homeowner.id)
      throw new ForbiddenException('Not your job');

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.jobApplication.update({
        where: { id: applicationId },
        data: { status: 'ACCEPTED' },
        include: APPLICATION_INCLUDE,
      });

      await tx.job.update({
        where: { id: app.jobId },
        data: { status: 'ACCEPTED' },
      });

      // Create booking automatically
      await tx.booking.create({
        data: {
          jobId: app.jobId,
          applicationId,
          artisanId: app.artisanId,
          homeownerId: homeowner.id,
          status: 'CONFIRMED',
        },
      });

      return updated;
    });
  }

  // ─── Reject ───────────────────────────────────────────────────────────────

  async reject(applicationId: string) {
    return this.prisma.jobApplication.update({
      where: { id: applicationId },
      data: { status: 'REJECTED' },
    });
  }

  // ─── Withdraw (artisan) ───────────────────────────────────────────────────

  async withdraw(applicationId: string) {
    return this.prisma.jobApplication.update({
      where: { id: applicationId },
      data: { status: 'WITHDRAWN' },
    });
  }

  // ─── Legacy: list for job (used by homeowner app) ─────────────────────────

  async listForJob(jobId: string) {
    return this.prisma.jobApplication.findMany({
      where: { jobId },
      include: APPLICATION_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
  }
}
