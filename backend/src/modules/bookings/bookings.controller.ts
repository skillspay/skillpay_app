import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Bookings')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  @ApiOperation({ summary: 'Accept a job application and book the artisan (Homeowner)' })
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { applicationId: string },
  ) {
    return this.bookingsService.create(user.id, body.applicationId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get booking details by ID' })
  findOne(@Param('id') id: string) {
    return this.bookingsService.findOne(id);
  }

  @Post(':id/complete')
  @ApiOperation({ summary: 'Complete a booking' })
  complete(@Param('id') id: string) {
    return this.bookingsService.complete(id);
  }
}
