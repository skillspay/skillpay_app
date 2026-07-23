import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Reviews')
@ApiBearerAuth('supabase-jwt')
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  @ApiOperation({ summary: 'Submit a review for a completed booking (Homeowner)' })
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { bookingId: string; rating: number; review?: string },
  ) {
    return this.reviewsService.create(user.id, body.bookingId, body.rating, body.review);
  }

  @Get('artisan/:artisanId')
  @ApiOperation({ summary: 'Get all reviews for an artisan' })
  getForArtisan(@Param('artisanId') artisanId: string) {
    return this.reviewsService.getForArtisan(artisanId);
  }
}
