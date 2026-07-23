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
import { JobsService } from './jobs.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Jobs')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller('jobs')
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  // Flutter (customer): GET /jobs/my-jobs
  @Get('my-jobs')
  @ApiOperation({ summary: 'Get homeowner\'s own jobs' })
  myJobs(@CurrentUser() user: AuthenticatedUser) {
    return this.jobsService.findForHomeowner(user.id);
  }

  // Flutter (workers): GET /jobs?status=PUBLISHED&limit=20
  @Get()
  @ApiOperation({ summary: 'List all jobs with optional filters' })
  findAll(
    @Query('status') status?: string,
    @Query('categoryId') categoryId?: string,
    @Query('limit') limit?: number,
    @Query('lat') lat?: number,
    @Query('lng') lng?: number,
  ) {
    return this.jobsService.findAll({ status, categoryId, limit, lat, lng });
  }

  // Flutter (customer): GET /jobs/:id
  @Get(':id')
  @ApiOperation({ summary: 'Get job by ID' })
  findOne(@Param('id') id: string) {
    return this.jobsService.findOne(id);
  }

  // Flutter (customer): POST /jobs
  @Post()
  @ApiOperation({ summary: 'Create a new job (homeowner)' })
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: {
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
    return this.jobsService.create(user.id, body);
  }

  // Flutter (customer): PATCH /jobs/:id/cancel
  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel a job' })
  cancel(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.jobsService.cancel(user.id, id);
  }
}
