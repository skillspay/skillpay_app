import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ApplicationsService } from './applications.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Applications')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller()
export class ApplicationsController {
  constructor(private readonly applicationsService: ApplicationsService) {}

  @Post('jobs/:jobId/apply')
  @ApiOperation({ summary: 'Apply to a job listing (Artisan)' })
  apply(
    @CurrentUser() user: AuthenticatedUser,
    @Param('jobId') jobId: string,
    @Body() body: { price: number; estimatedDuration?: string; proposal: string },
  ) {
    return this.applicationsService.apply(user.id, jobId, body);
  }

  @Get('jobs/:jobId/applications')
  @ApiOperation({ summary: 'List applications for a job listing (Homeowner)' })
  listForJob(@Param('jobId') jobId: string) {
    return this.applicationsService.listForJob(jobId);
  }
}
