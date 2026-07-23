import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

const BOOKING_INCLUDE = {
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
  application: { select: { id: true, price: true, proposal: true } },
  artisan: { select: { id: true, fullName: true, profilePhoto: true } },
  homeowner: { select: { id: true, fullName: true, profilePhoto: true } },
  payment: true,
};

@Injectable()
export class BookingsService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── Create booking from application ─────────────────────────────────────

  async create(homeownerUserId: string, applicationId: string) {
    const homeowner = await this.prisma.homeowner.findUnique({
      where: { userId: homeownerUserId },
    });
    if (!homeowner) throw new NotFoundException('Homeowner profile not found');

    const app = await this.prisma.jobApplication.findUnique({
      where: { id: applicationId },
      include: { job: true },
    });
    if (!app) throw new NotFoundException(`Application ${applicationId} not found`);
    if (app.job.homeownerId !== homeowner.id)
      throw new BadRequestException('Not your job');

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
        include: BOOKING_INCLUDE,
      });
    });
  }

  // ─── Artisan: active bookings ─────────────────────────────────────────────

  async findForArtisan(userId: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { userId },
    });
    if (!artisan) return [];

    return this.prisma.booking.findMany({
      where: {
        artisanId: artisan.id,
        status: { in: ['CONFIRMED', 'IN_PROGRESS'] },
      },
      include: BOOKING_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
  }

  // ─── Artisan: completed history ────────────────────────────────────────────

  async findHistoryForArtisan(userId: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { userId },
    });
    if (!artisan) return [];

    return this.prisma.booking.findMany({
      where: {
        artisanId: artisan.id,
        status: { in: ['COMPLETED', 'CANCELLED'] },
      },
      include: BOOKING_INCLUDE,
      orderBy: { completionDate: 'desc' },
    });
  }

  // ─── Single booking ───────────────────────────────────────────────────────

  async findOne(id: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id },
      include: BOOKING_INCLUDE,
    });
    if (!booking) throw new NotFoundException(`Booking ${id} not found`);
    return booking;
  }

  // ─── Start job ────────────────────────────────────────────────────────────

  async start(id: string) {
    const booking = await this.prisma.booking.findUnique({ where: { id } });
    if (!booking) throw new NotFoundException(`Booking ${id} not found`);

    return this.prisma.$transaction(async (tx) => {
      await tx.job.update({
        where: { id: booking.jobId },
        data: { status: 'IN_PROGRESS' },
      });
      return tx.booking.update({
        where: { id },
        data: { status: 'IN_PROGRESS', startDate: new Date() },
        include: BOOKING_INCLUDE,
      });
    });
  }

  // ─── Complete job ─────────────────────────────────────────────────────────

  async complete(id: string) {
    const booking = await this.prisma.booking.findUnique({ where: { id } });
    if (!booking) throw new NotFoundException(`Booking ${id} not found`);

    return this.prisma.$transaction(async (tx) => {
      // Update artisan completed jobs count
      await tx.artisan.update({
        where: { id: booking.artisanId },
        data: { completedJobs: { increment: 1 } },
      });
      await tx.job.update({
        where: { id: booking.jobId },
        data: { status: 'COMPLETED' },
      });
      return tx.booking.update({
        where: { id },
        data: { status: 'COMPLETED', completionDate: new Date() },
        include: BOOKING_INCLUDE,
      });
    });
  }
}
