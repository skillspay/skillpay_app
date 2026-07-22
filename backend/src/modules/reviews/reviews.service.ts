import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(homeownerUserId: string, bookingId: string, rating: number, review?: string) {
    if (rating < 1 || rating > 5) {
      throw new BadRequestException('Rating must be between 1 and 5');
    }

    const homeowner = await this.prisma.homeowner.findUnique({ where: { userId: homeownerUserId } });
    if (!homeowner) throw new NotFoundException('Homeowner profile not found');

    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { review: true },
    });
    if (!booking) throw new NotFoundException(`Booking ${bookingId} not found`);
    if (booking.review) throw new BadRequestException('Review already submitted for this booking');

    const newReview = await this.prisma.$transaction(async (tx) => {
      const r = await tx.review.create({
        data: {
          bookingId,
          artisanId: booking.artisanId,
          homeownerId: homeowner.id,
          rating,
          review,
        },
      });

      // Recalculate artisan average rating
      const agg = await tx.review.aggregate({
        where: { artisanId: booking.artisanId },
        _avg: { rating: true },
        _count: { rating: true },
      });

      await tx.artisan.update({
        where: { id: booking.artisanId },
        data: { averageRating: agg._avg.rating ?? 0 },
      });

      return r;
    });

    return newReview;
  }

  async getForArtisan(artisanId: string) {
    return this.prisma.review.findMany({
      where: { artisanId },
      include: { homeowner: true },
      orderBy: { createdAt: 'desc' },
    });
  }
}
