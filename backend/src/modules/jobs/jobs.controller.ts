import { Controller, Get, Post, Param, Body, Query, UseGuards } from '@nestjs/common';
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

  @Post()
  @ApiOperation({ summary: 'Post a new job (Homeowner)' })
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { title: string; description: string; budget: number; categoryId: string; preferredDate?: Date; latitude?: number; longitude?: number; address?: string; images?: string[] },
  ) {
    return this.jobsService.create(user.id, body);
  }

  @Get()
  @ApiOperation({ summary: 'List all jobs' })
  findAll(@Query('categoryId') categoryId?: string) {
    return this.jobsService.findAll(categoryId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get job by ID' })
  findOne(@Param('id') id: string) {
    return this.jobsService.findOne(id);
  }
}
