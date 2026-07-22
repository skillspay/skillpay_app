import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class JobsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(homeownerUserId: string, data: { title: string; description: string; budget: number; categoryId: string; preferredDate?: Date; latitude?: number; longitude?: number; address?: string; images?: string[] }) {
    const homeowner = await this.prisma.homeowner.findUnique({ where: { userId: homeownerUserId } });
    if (!homeowner) {
      throw new NotFoundException('Homeowner profile not found');
    }

    return this.prisma.job.create({
      data: {
        homeownerId: homeowner.id,
        categoryId: data.categoryId,
        title: data.title,
        description: data.description,
        budget: data.budget,
        preferredDate: data.preferredDate,
        latitude: data.latitude,
        longitude: data.longitude,
        address: data.address,
        images: data.images,
        status: 'PENDING',
      },
    });
  }

  async findAll(categoryId?: string) {
    return this.prisma.job.findMany({
      where: {
        ...(categoryId ? { categoryId } : {}),
      },
      include: { category: true, homeowner: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const job = await this.prisma.job.findUnique({
      where: { id },
      include: { category: true, homeowner: true, applications: { include: { artisan: true } } },
    });
    if (!job) {
      throw new NotFoundException(`Job with ID ${id} not found`);
    }
    return job;
  }
}
