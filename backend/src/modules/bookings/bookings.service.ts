import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class BookingsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(homeownerUserId: string, applicationId: string) {
    const homeowner = await this.prisma.homeowner.findUnique({ where: { userId: homeownerUserId } });
    if (!homeowner) {
      throw new NotFoundException('Homeowner profile not found');
    }

    const app = await this.prisma.jobApplication.findUnique({
      where: { id: applicationId },
      include: { job: true },
    });
    if (!app) {
      throw new NotFoundException(`Job application ${applicationId} not found`);
    }

    if (app.job.homeownerId !== homeowner.id) {
      throw new BadRequestException('Unauthorized action: not the job owner');
    }

    // Create booking and mark application as ACCEPTED and job as ACCEPTED
    return this.prisma.$transaction(async (tx) => {
      await tx.jobApplication.update({
        where: { id: applicationId },
        data: { status: 'ACCEPTED' },
      });

      await tx.job.update({
        where: { id: app.jobId },
        data: { status: 'ACCEPTED' },
      });

      return tx.booking.create({
        data: {
          jobId: app.jobId,
          applicationId,
          artisanId: app.artisanId,
          homeownerId: homeowner.id,
          status: 'CONFIRMED',
        },
      });
    });
  }

  async findOne(id: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id },
      include: { job: true, application: true, artisan: true, homeowner: true, payment: true },
    });
    if (!booking) {
      throw new NotFoundException(`Booking with ID ${id} not found`);
    }
    return booking;
  }

  async complete(id: string) {
    const booking = await this.prisma.booking.findUnique({ where: { id } });
    if (!booking) {
      throw new NotFoundException(`Booking ${id} not found`);
    }

    return this.prisma.booking.update({
      where: { id },
      data: {
        status: 'COMPLETED',
        completionDate: new Date(),
      },
    });
  }
}
