import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ReportStatus, VerificationStatus } from '@prisma/client';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── Verification Management ────────────────────────────────────────────────

  async getPendingVerifications() {
    return this.prisma.verificationDocument.findMany({
      where: { status: VerificationStatus.PENDING },
      include: { artisan: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async reviewVerificationDocument(
    docId: string,
    status: 'VERIFIED' | 'REJECTED',
    adminNote?: string,
  ) {
    const doc = await this.prisma.verificationDocument.findUnique({ where: { id: docId } });
    if (!doc) throw new NotFoundException(`Document ${docId} not found`);

    const updatedDoc = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.verificationDocument.update({
        where: { id: docId },
        data: { status, adminNote },
      });

      // If approved, check if all artisan docs are now VERIFIED and upgrade artisan status
      if (status === 'VERIFIED') {
        const pending = await tx.verificationDocument.count({
          where: { artisanId: doc.artisanId, status: VerificationStatus.PENDING },
        });
        if (pending === 0) {
          await tx.artisan.update({
            where: { id: doc.artisanId },
            data: { verificationStatus: VerificationStatus.VERIFIED },
          });
          await tx.user.updateMany({
            where: { artisan: { id: doc.artisanId } },
            data: { isVerified: true },
          });
        }
      }

      return updated;
    });

    return updatedDoc;
  }

  // ─── Reports / Disputes ─────────────────────────────────────────────────────

  async getAllReports() {
    return this.prisma.report.findMany({
      include: {
        reportedBy: { select: { id: true, email: true } },
        reportedUser: { select: { id: true, email: true } },
        booking: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async resolveReport(reportId: string, adminNote: string) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw new NotFoundException(`Report ${reportId} not found`);
    return this.prisma.report.update({
      where: { id: reportId },
      data: { status: ReportStatus.RESOLVED, adminNote },
    });
  }

  async dismissReport(reportId: string, adminNote: string) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw new NotFoundException(`Report ${reportId} not found`);
    return this.prisma.report.update({
      where: { id: reportId },
      data: { status: ReportStatus.DISMISSED, adminNote },
    });
  }

  // ─── Bookings Overview ──────────────────────────────────────────────────────

  async getAllBookings() {
    return this.prisma.booking.findMany({
      include: {
        homeowner: { select: { id: true, fullName: true } },
        artisan: { select: { id: true, fullName: true } },
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ─── Payments Overview ──────────────────────────────────────────────────────

  async getAllPayments() {
    return this.prisma.payment.findMany({
      include: {
        homeowner: { select: { id: true, fullName: true } },
        artisan: { select: { id: true, fullName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getPaymentStats() {
    const [all, stripe, paypal] = await Promise.all([
      this.prisma.payment.aggregate({
        where: { status: 'COMPLETED' },
        _sum: { amount: true },
      }),
      this.prisma.payment.aggregate({
        where: { status: 'COMPLETED', gateway: 'STRIPE' },
        _sum: { amount: true },
      }),
      this.prisma.payment.aggregate({
        where: { status: 'COMPLETED', gateway: 'PAYPAL' },
        _sum: { amount: true },
      }),
    ]);

    return {
      totalVolume: Number(all._sum.amount ?? 0),
      stripeVolume: Number(stripe._sum.amount ?? 0),
      paypalVolume: Number(paypal._sum.amount ?? 0),
    };
  }

  // ─── Audit Log ──────────────────────────────────────────────────────────────

  async logAction(adminId: string, action: string, table?: string, recordId?: string, metadata?: any) {
    return this.prisma.adminLog.create({
      data: { adminId, action, table, recordId, metadata },
    });
  }

  async getAdminLogs() {
    return this.prisma.adminLog.findMany({
      include: { admin: { select: { id: true, email: true } } },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  }
}
