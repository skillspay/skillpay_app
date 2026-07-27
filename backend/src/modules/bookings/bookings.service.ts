import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import { WalletService } from '../wallet/wallet.service';
import { SettingsService } from '../settings/settings.service';

const BOOKING_INCLUDE = {
  job: {
    select: {
      id: true,
      title: true,
      address: true,
      budget: true,
      status: true,
      description: true,
      timeline: true,
      preferredDate: true,
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
  constructor(
    private readonly prisma: PrismaService,
    private readonly mailService: MailService,
    private readonly walletService: WalletService,
    private readonly settingsService: SettingsService,
  ) {}

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

  // ─── Create booking directly (no application) ─────────────────────────────

  async createDirect(homeownerUserId: string, jobId: string, artisanId: string) {
    const homeowner = await this.prisma.homeowner.findUnique({
      where: { userId: homeownerUserId },
    });
    if (!homeowner) throw new NotFoundException('Homeowner profile not found');

    const job = await this.prisma.job.findUnique({ where: { id: jobId } });
    if (!job || job.homeownerId !== homeowner.id) throw new NotFoundException('Job not found');

    // Check if application exists
    let app = await this.prisma.jobApplication.findFirst({
      where: { jobId, artisanId },
    });

    if (!app) {
      // Create synthetic application
      app = await this.prisma.jobApplication.create({
        data: {
          jobId,
          artisanId,
          price: job.budget,
          proposal: 'Direct hire',
          status: 'ACCEPTED',
        }
      });
    }

    const result = await this.prisma.$transaction(async (tx) => {
      await tx.jobApplication.update({
        where: { id: app.id },
        data: { status: 'ACCEPTED' },
      });
      await tx.job.update({
        where: { id: jobId },
        data: { status: 'ACCEPTED' },
      });
      return tx.booking.create({
        data: {
          jobId,
          applicationId: app.id,
          artisanId,
          homeownerId: homeowner.id,
          status: 'CONFIRMED',
          payment: {
            create: {
              homeownerId: homeowner.id,
              artisanId,
              amount: Number(job.budget) * 0.7,
              gateway: 'STRIPE',
              paymentMethod: 'CARD',
              status: 'COMPLETED',
              reference: `pay_${Date.now()}_${Math.random().toString(36).substring(7)}`,
            }
          }
        },
        include: BOOKING_INCLUDE,
      });
    });

    // Send email to admin
    this.mailService.sendNotificationEmail(
      'admin@skillspays.com',
      'New Job Hired & Payment Received',
      `A new payment of $${(Number(job.budget) * 0.7).toFixed(2)} was successfully received for job "${job.title}". The booking ID is ${result.id}.`
    ).catch(e => console.error('Failed to send admin email', e));

    return result;
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
    const booking = await this.prisma.booking.findUnique({ 
      where: { id },
      include: {
        application: true,
        job: true,
        artisan: true,
      },
    });
    if (!booking) throw new NotFoundException(`Booking ${id} not found`);

    return this.prisma.$transaction(async (tx) => {
      await tx.job.update({
        where: { id: booking.jobId },
        data: { status: 'COMPLETED' },
      });

      // Notify customer (via email or other notification means)
      try {
        const homeownerUser = await this.prisma.user.findUnique({ where: { id: booking.homeowner.userId } });
        if (homeownerUser && homeownerUser.email) {
          await this.mailService.sendNotificationEmail(
            homeownerUser.email,
            'Job Completed - Action Required',
            `Your job "${booking.job.title}" has been marked as completed by the artisan. Please log in to approve the job and release the final payment.`
          );
        }
      } catch (e) {
        console.error('Failed to send completion email to customer', e);
      }

      return tx.booking.update({
        where: { id },
        data: { status: 'COMPLETED', completionDate: new Date() },
        include: BOOKING_INCLUDE,
      });
    });
  }

  // ─── Approve and Pay ──────────────────────────────────────────────────────

  async approveAndPay(id: string, customerUserId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id },
      include: {
        application: true,
        job: true,
        artisan: true,
        homeowner: true,
      },
    });

    if (!booking) throw new NotFoundException(`Booking ${id} not found`);
    if (booking.homeowner.userId !== customerUserId) throw new BadRequestException('Not your booking');
    if (booking.status !== 'COMPLETED') throw new BadRequestException('Booking is not completed yet');

    return this.prisma.$transaction(async (tx) => {
      // 1. Mark artisan completed jobs count increment (since it's now officially approved)
      await tx.artisan.update({
        where: { id: booking.artisanId },
        data: { completedJobs: { increment: 1 } },
      });

      // 2. Process final payment (Simulation - Assume customer pays or balance deducted)
      // TODO: Actual payment gateway integration would go here if charging a card.

      // 3. Calculate payout and credit worker's wallet
      const amountStr = booking.application?.price?.toString() || booking.job?.budget?.toString();
      const amount = parseFloat(amountStr || '0');

      if (amount > 0) {
        const commissionPercent = await this.settingsService.getCommissionPercentage();
        const deduction = amount * (commissionPercent / 100);
        const payout = amount - deduction;
        
        await this.walletService.credit(
          booking.artisan.userId, 
          payout, 
          `Payment for job ${booking.job?.title || id} (Admin commission: ${commissionPercent}%)`
        );
      }

      // Return the updated booking
      return tx.booking.findUnique({
        where: { id },
        include: BOOKING_INCLUDE,
      });
    });
  }

  async approveAndPayByJob(jobId: string, customerUserId: string) {
    const booking = await this.prisma.booking.findFirst({
      where: { jobId },
      orderBy: { createdAt: 'desc' },
    });
    if (!booking) throw new NotFoundException('Booking not found for this job');
    return this.approveAndPay(booking.id, customerUserId);
  }
}
