import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Job, Artisan } from '@prisma/client';

@Injectable()
export class AiMatchService {
  private readonly logger = new Logger(AiMatchService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Automatically finds and invites top matching Artisans to a new Job.
   */
  async matchJobWithArtisans(job: Job) {
    try {
      this.logger.log(`Starting AI Match for Job ${job.id}`);

      // 1. Fetch available artisans in the same category
      // If job has no category or location, we can't match accurately
      if (!job.categoryId || job.latitude == null || job.longitude == null) {
        this.logger.warn('Job is missing category or coordinates, skipping match.');
        return;
      }

      const candidateArtisans = await this.prisma.artisan.findMany({
        where: {
          categories: {
            some: { categoryId: job.categoryId },
          },
          latitude: { not: null },
          longitude: { not: null },
        },
      });

      if (candidateArtisans.length === 0) {
        this.logger.log('No candidate artisans found for this category.');
        return;
      }

      // 2. Calculate distance and score
      const MAX_DISTANCE_KM = 30; // Max 30km radius
      const scoredArtisans = candidateArtisans
        .map((artisan) => {
          const distance = this.calculateDistance(
            job.latitude!,
            job.longitude!,
            artisan.latitude!,
            artisan.longitude!,
          );
          return { artisan, distance };
        })
        .filter((match) => match.distance <= MAX_DISTANCE_KM)
        .map((match) => {
          // A simple score calculation
          // 0 to 100 based on distance (closer = better, up to 50 pts)
          const distanceScore = Math.max(0, 50 - (match.distance / MAX_DISTANCE_KM) * 50);
          
          // Rating score (up to 50 pts)
          const ratingScore = (match.artisan.averageRating / 5) * 50;

          return {
            ...match,
            score: distanceScore + ratingScore,
          };
        });

      // Sort by best score descending
      scoredArtisans.sort((a, b) => b.score - a.score);

      // Take top 5
      const topMatches = scoredArtisans.slice(0, 5);

      if (topMatches.length === 0) {
        this.logger.log('No artisans found within the radius.');
        return;
      }

      this.logger.log(`Found ${topMatches.length} top matches for Job ${job.id}.`);

      // 3. Create JobApplications (as invitations) for these top matches
      const applicationsData = topMatches.map((match) => ({
        jobId: job.id,
        artisanId: match.artisan.id,
        price: job.budget, // Assume they are invited at the job's budget initially
        proposal: `AI Match: You have been automatically matched with this job because it fits your profile and is ${match.distance.toFixed(1)}km away.`,
        status: 'PENDING' as any,
        isAiMatched: true,
      }));

      await this.prisma.jobApplication.createMany({
        data: applicationsData,
        skipDuplicates: true,
      });

      this.logger.log(`Successfully created ${topMatches.length} AI-matched applications.`);
      
      // TODO: Here we could integrate Firebase Cloud Messaging to send Push Notifications
      
    } catch (error) {
      this.logger.error(`Failed to run AI matching: ${error.message}`, error.stack);
    }
  }

  /**
   * Haversine formula to calculate distance in km between two lat/lng coordinates.
   */
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Earth's radius in km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) *
        Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
