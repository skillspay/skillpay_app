import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
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

  // Flutter (workers): GET /bookings/mine  — active bookings for artisan
  @Get('mine')
  @ApiOperation({ summary: 'Active bookings for current artisan' })
  mine(@CurrentUser() user: AuthenticatedUser) {
    return this.bookingsService.findForArtisan(user.id);
  }

  // Flutter (workers): GET /bookings/my-history  — completed bookings
  @Get('my-history')
  @ApiOperation({ summary: 'Completed booking history for current artisan' })
  myHistory(@CurrentUser() user: AuthenticatedUser) {
    return this.bookingsService.findHistoryForArtisan(user.id);
  }

  // Create booking from accepted application (homeowner)
  @Post()
  @ApiOperation({ summary: 'Create booking from accepted application (homeowner)' })
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { applicationId: string },
  ) {
    return this.bookingsService.create(user.id, body.applicationId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get booking by ID' })
  findOne(@Param('id') id: string) {
    return this.bookingsService.findOne(id);
  }

  @Patch(':id/start')
  @ApiOperation({ summary: 'Mark booking as in progress (artisan)' })
  start(@Param('id') id: string) {
    return this.bookingsService.start(id);
  }

  @Patch(':id/complete')
  @ApiOperation({ summary: 'Mark booking as completed' })
  complete(@Param('id') id: string) {
    return this.bookingsService.complete(id);
  }
}
