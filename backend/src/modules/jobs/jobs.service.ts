import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

const JOB_INCLUDE = {
  category: { select: { id: true, name: true, icon: true } },
  homeowner: {
    select: { id: true, fullName: true, profilePhoto: true, defaultAddress: true },
  },
  _count: { select: { applications: true } },
};

@Injectable()
export class JobsService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── Homeowner's own jobs ─────────────────────────────────────────────────

  async findForHomeowner(userId: string) {
    const homeowner = await this.prisma.homeowner.findUnique({
      where: { userId },
    });
    if (!homeowner) return [];

    const jobs = await this.prisma.job.findMany({
      where: { homeownerId: homeowner.id },
      include: JOB_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });

    return jobs.map(this._formatJob);
  }

  // ─── Public job listing (artisans browse) ─────────────────────────────────

  async findAll(filters: {
    status?: string;
    categoryId?: string;
    limit?: number;
    lat?: number;
    lng?: number;
  }) {
    const { status, categoryId, limit } = filters;

    const jobs = await this.prisma.job.findMany({
      where: {
        status: (status as any) ?? 'PUBLISHED',
        ...(categoryId ? { categoryId } : {}),
      },
      include: JOB_INCLUDE,
      orderBy: { createdAt: 'desc' },
      take: limit ? Number(limit) : 50,
    });

    return jobs.map(this._formatJob);
  }

  // ─── Single job ───────────────────────────────────────────────────────────

  async findOne(id: string) {
    const job = await this.prisma.job.findUnique({
      where: { id },
      include: {
        ...JOB_INCLUDE,
        applications: {
          include: {
            artisan: {
              select: {
                id: true,
                fullName: true,
                profilePhoto: true,
                averageRating: true,
                completedJobs: true,
              },
            },
          },
        },
      },
    });
    if (!job) throw new NotFoundException(`Job ${id} not found`);
    return this._formatJob(job);
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  async create(
    userId: string,
    data: {
      categoryId?: string;
      title: string;
      description: string;
      budget: number;
      address?: string;
      latitude?: number;
      longitude?: number;
      preferredDate?: string;
      images?: string[];
    },
  ) {
    const homeowner = await this.prisma.homeowner.findUnique({
      where: { userId },
    });
    if (!homeowner) throw new NotFoundException('Homeowner profile not found');

    const job = await this.prisma.job.create({
      data: {
        homeownerId: homeowner.id,
        categoryId: data.categoryId,
        title: data.title,
        description: data.description,
        budget: data.budget,
        address: data.address,
        latitude: data.latitude,
        longitude: data.longitude,
        preferredDate: data.preferredDate ? new Date(data.preferredDate) : null,
        images: data.images ?? [],
        status: 'PUBLISHED',
      },
      include: JOB_INCLUDE,
    });

    return this._formatJob(job);
  }

  // ─── Cancel ───────────────────────────────────────────────────────────────

  async cancel(userId: string, jobId: string) {
    const homeowner = await this.prisma.homeowner.findUnique({
      where: { userId },
    });
    if (!homeowner) throw new NotFoundException('Homeowner profile not found');

    const job = await this.prisma.job.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundException(`Job ${jobId} not found`);
    if (job.homeownerId !== homeowner.id)
      throw new ForbiddenException('Not your job');

    return this.prisma.job.update({
      where: { id: jobId },
      data: { status: 'CANCELLED' },
      include: JOB_INCLUDE,
    });
  }

  // ─── Helper: flatten _count into applicationCount ─────────────────────────

  private _formatJob(job: any) {
    const { _count, ...rest } = job;
    return {
      ...rest,
      applicationCount: _count?.applications ?? 0,
    };
  }
}
