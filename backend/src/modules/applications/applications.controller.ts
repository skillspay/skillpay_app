import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ApplicationsService } from './applications.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Applications')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller('applications')
export class ApplicationsController {
  constructor(
    private readonly applicationsService: ApplicationsService,
  ) {}

  // Flutter: POST /applications
  @Post()
  @ApiOperation({ summary: 'Submit a job application (artisan)' })
  apply(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { jobId: string; price: number; estimatedDuration?: string; proposal: string },
  ) {
    return this.applicationsService.apply(user.id, body.jobId, body);
  }

  // Flutter: GET /applications?status=PENDING  (homeowner — list proposals on their jobs)
  @Get()
  @ApiOperation({ summary: 'List applications for homeowner jobs' })
  listForHomeowner(
    @CurrentUser() user: AuthenticatedUser,
    @Query('status') status?: string,
    @Query('jobId') jobId?: string,
  ) {
    return this.applicationsService.listForHomeowner(user.id, status, jobId);
  }

  // Flutter: GET /applications/mine  (artisan — list own applications)
  @Get('mine')
  @ApiOperation({ summary: 'List artisan own applications' })
  listMine(
    @CurrentUser() user: AuthenticatedUser,
    @Query('status') status?: string,
  ) {
    return this.applicationsService.listForArtisan(user.id, status);
  }

  // Flutter: GET /applications/my-jobs  (artisan — jobs they applied to)
  @Get('my-jobs')
  @ApiOperation({ summary: 'Jobs the artisan has applied to' })
  myJobs(@CurrentUser() user: AuthenticatedUser) {
    return this.applicationsService.jobsAppliedTo(user.id);
  }

  // Flutter: GET /applications/:id
  @Get(':id')
  @ApiOperation({ summary: 'Get application by ID' })
  findOne(@Param('id') id: string) {
    return this.applicationsService.findOne(id);
  }

  // Flutter: PATCH /applications/:id/accept
  @Patch(':id/accept')
  @ApiOperation({ summary: 'Accept an application (homeowner)' })
  accept(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.applicationsService.accept(user.id, id);
  }

  // Flutter: PATCH /applications/:id/reject
  @Patch(':id/reject')
  @ApiOperation({ summary: 'Reject an application (homeowner)' })
  reject(@Param('id') id: string) {
    return this.applicationsService.reject(id);
  }

  // Flutter: PATCH /applications/:id/withdraw
  @Patch(':id/withdraw')
  @ApiOperation({ summary: 'Withdraw an application (artisan)' })
  withdraw(@Param('id') id: string) {
    return this.applicationsService.withdraw(id);
  }
}
