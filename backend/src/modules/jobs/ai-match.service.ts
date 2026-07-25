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
      // If job has no category, we will match ANY artisan in the area
      if (!job.categoryId) {
        this.logger.warn('Job is missing category, matching by location only.');
      }

      // Check if we have coordinates
      const hasCoords = job.latitude != null && job.longitude != null;
      let candidateArtisans: any[] = [];

      if (hasCoords) {
        candidateArtisans = await this.prisma.artisan.findMany({
          where: {
            ...(job.categoryId ? {
              categories: {
                some: { categoryId: job.categoryId },
              }
            } : {}),
            latitude: { not: null },
            longitude: { not: null },
          },
          include: { user: true },
        });
      } else if (job.address) {
        // Fallback to string-based town/city matching
        // Extract the town (assuming format "Address, Town, State" or just "Town")
        const parts = job.address.split(',').map(s => s.trim());
        const searchKeywords = parts.length > 1 ? parts.slice(-2) : parts;
        
        // Find artisans where their businessName, fullName, or ANY user address matches
        candidateArtisans = await this.prisma.artisan.findMany({
          where: {
            ...(job.categoryId ? {
              categories: {
                some: { categoryId: job.categoryId },
              }
            } : {}),
            // We don't have artisan address string directly in artisan table,
            // we should search by their user addresses
            user: {
              addresses: {
                some: {
                  OR: searchKeywords.map(kw => ({
                    address: { contains: kw, mode: 'insensitive' }
                  }))
                }
              }
            }
          },
          include: { user: true },
        });
      }

      if (candidateArtisans.length === 0) {
        this.logger.log('No candidate artisans found for this category/location.');
        return;
      }

      // 2. Calculate distance and score
      const MAX_DISTANCE_KM = 30; // Max 30km radius
      const topMatches = candidateArtisans
        .map((artisan) => {
          const distance = hasCoords && artisan.latitude && artisan.longitude
            ? this.calculateDistance(
                job.latitude!,
                job.longitude!,
                artisan.latitude,
                artisan.longitude,
              )
            : 0;
          return { artisan, distance };
        })
        .filter((match) => !hasCoords || match.distance <= MAX_DISTANCE_KM)
        .map((match) => {
          // A simple score calculation
          const distanceScore = hasCoords && match.artisan.latitude && match.artisan.longitude
            ? Math.max(0, 50 - (match.distance / MAX_DISTANCE_KM) * 50)
            : 25; // Default score for string match
          
          // Rating score (up to 50 pts)
          const ratingScore = (match.artisan.averageRating / 5) * 50;

          const totalScore = distanceScore + ratingScore;
          return { artisan: match.artisan, distance: match.distance, score: totalScore };
        })
        .sort((a, b) => b.score - a.score)
        .slice(0, 5); // Take top 5

      this.logger.log(`Found ${topMatches.length} matching artisans`);

      if (topMatches.length === 0) {
        this.logger.log('No artisans found within the radius or area.');
        return;
      }

      this.logger.log(`Found ${topMatches.length} top matches for Job ${job.id}.`);

      // 3. Create JobApplications (as invitations) for these top matches
      const applicationsData = topMatches.map((match) => ({
        jobId: job.id,
        artisanId: match.artisan.id,
        price: job.budget, // Assume they are invited at the job's budget initially
        proposal: `AI Match: You have been automatically matched with this job because it fits your profile ${hasCoords ? `and is ${match.distance.toFixed(1)}km away.` : 'and is in your area.'}`,
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
  public calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
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
