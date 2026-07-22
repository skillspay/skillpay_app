import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';
import { Role } from '@prisma/client';

@ApiTags('Admin')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ─── Verification Endpoints ────────────────────────────────────────────────

  @Get('verifications/pending')
  @ApiOperation({ summary: 'List pending artisan verification documents' })
  getPendingVerifications() {
    return this.adminService.getPendingVerifications();
  }

  @Post('verifications/:id')
  @ApiOperation({ summary: 'Review and approve/reject a verification document' })
  async reviewVerification(
    @CurrentUser() admin: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: { status: 'VERIFIED' | 'REJECTED'; adminNote?: string },
  ) {
    const result = await this.adminService.reviewVerificationDocument(id, body.status, body.adminNote);
    await this.adminService.logAction(admin.id, `Verification ${body.status}`, 'verification_documents', id, body);
    return result;
  }

  // ─── Reports Endpoints ─────────────────────────────────────────────────────

  @Get('reports')
  @ApiOperation({ summary: 'List all user reports/disputes' })
  getAllReports() {
    return this.adminService.getAllReports();
  }

  @Post('reports/:id/resolve')
  @ApiOperation({ summary: 'Resolve a report' })
  async resolveReport(
    @CurrentUser() admin: AuthenticatedUser,
    @Param('id') id: string,
    @Body('adminNote') adminNote: string,
  ) {
    const result = await this.adminService.resolveReport(id, adminNote);
    await this.adminService.logAction(admin.id, 'Report RESOLVED', 'reports', id, { adminNote });
    return result;
  }

  @Post('reports/:id/dismiss')
  @ApiOperation({ summary: 'Dismiss a report' })
  async dismissReport(
    @CurrentUser() admin: AuthenticatedUser,
    @Param('id') id: string,
    @Body('adminNote') adminNote: string,
  ) {
    const result = await this.adminService.dismissReport(id, adminNote);
    await this.adminService.logAction(admin.id, 'Report DISMISSED', 'reports', id, { adminNote });
    return result;
  }

  // ─── Bookings Overview ─────────────────────────────────────────────────────

  @Get('bookings')
  @ApiOperation({ summary: 'All platform bookings (admin view)' })
  getAllBookings() {
    return this.adminService.getAllBookings();
  }

  // ─── Payments Overview ─────────────────────────────────────────────────────

  @Get('payments')
  @ApiOperation({ summary: 'All platform payments (admin view)' })
  getAllPayments() {
    return this.adminService.getAllPayments();
  }

  @Get('payments/stats')
  @ApiOperation({ summary: 'Payment stats and gateway revenue breakdown' })
  getPaymentStats() {
    return this.adminService.getPaymentStats();
  }

  // ─── Audit Log ─────────────────────────────────────────────────────────────

  @Get('logs')
  @ApiOperation({ summary: 'Admin activity audit logs' })
  getLogs() {
    return this.adminService.getAdminLogs();
  }
}
