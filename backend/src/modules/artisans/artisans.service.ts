import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RedisService } from '../../common/redis/redis.service';
import { Prisma, VerificationDocumentType } from '@prisma/client';

const ARTISAN_INCLUDE: Prisma.ArtisanInclude = {
  user: { select: { id: true, email: true, phone: true } },
  categories: { include: { category: true } },
  verificationDocuments: true,
  posts: { orderBy: { createdAt: 'desc' } },
};

const PROFILE_TTL = 120;   // 2 minutes – artisan profiles change occasionally
const NEARBY_TTL  = 300;   // 5 minutes – search results

@Injectable()
export class ArtisansService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  private profileKey(userId: string) { return `artisan:profile:${userId}`; }
  private byIdKey(artisanId: string) { return `artisan:id:${artisanId}`; }

  // ─── Get or create profile ────────────────────────────────────────────────

  async getProfile(userId: string) {
    const cacheKey = this.profileKey(userId);
    const cached = await this.redis.get<any>(cacheKey);
    if (cached) return cached;

    let profile = await this.prisma.artisan.findUnique({
      where: { userId },
      include: ARTISAN_INCLUDE,
    });

    // Auto-create artisan profile on first access if it doesn't exist
    if (!profile) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, email: true },
      });
      if (!user) throw new NotFoundException('User not found');

      profile = await this.prisma.artisan.create({
        data: {
          userId,
          fullName: user.email.split('@')[0], // temporary name until updated
        },
        include: ARTISAN_INCLUDE,
      });
    }

    await this.redis.set(cacheKey, profile, PROFILE_TTL);
    return profile;
  }

  // ─── Update profile ───────────────────────────────────────────────────────

  async updateProfile(
    userId: string,
    data: {
      businessName?: string;
      fullName?: string;
      bio?: string;
      coverLetter?: string;
      experience?: string;
      yearsExperience?: number;
      hourlyRate?: number;
      profilePhoto?: string;
      availabilityStatus?: any;
      latitude?: number;
      longitude?: number;
      basedIn?: string;
      workPreference?: string;
    },
  ) {
    // Ensure profile exists
    await this.getProfile(userId);

    const result = await this.prisma.artisan.update({
      where: { userId },
      data,
      include: ARTISAN_INCLUDE,
    });
    // Invalidate caches
    await this.redis.del(this.profileKey(userId));
    await this.redis.del(this.byIdKey(result.id));
    return result;
  }

  // ─── Nearby artisans ──────────────────────────────────────────────────────

  async findNearby(filters: {
    categoryId?: string;
    lat?: number;
    lng?: number;
    radiusKm?: number;
    limit?: number;
    search?: string;
    location?: string;
  }) {
    const { categoryId, limit, search, lat, lng, radiusKm, location } = filters;

    // Build a deterministic cache key from the filter params
    const cacheKey = `artisans:nearby:${categoryId ?? ''}:${search ?? ''}:${location ?? ''}:${lat ?? ''}:${lng ?? ''}:${radiusKm ?? ''}:${limit ?? 20}`;
    const cached = await this.redis.get<any[]>(cacheKey);
    if (cached) return cached;

    const data = await this.prisma.artisan.findMany({
      where: {
        availabilityStatus: 'AVAILABLE',
        ...(categoryId
          ? { categories: { some: { categoryId } } }
          : {}),
        ...(location
          ? { basedIn: { contains: location, mode: 'insensitive' } }
          : {}),
        ...(search
          ? {
              OR: [
                { fullName: { contains: search, mode: 'insensitive' } },
                { businessName: { contains: search, mode: 'insensitive' } },
                { bio: { contains: search, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      include: {
        ...ARTISAN_INCLUDE,
        _count: { select: { verificationDocuments: true } },
      },
      orderBy: { averageRating: 'desc' },
      take: limit ? Number(limit) : 30,
    });

    let results = data.map((artisan) => {
      let distanceKm: number | null = null;
      if (lat != null && lng != null && artisan.latitude != null && artisan.longitude != null) {
        const rawDist = this.calculateDistance(lat, lng, artisan.latitude, artisan.longitude);
        distanceKm = Math.round(rawDist * 10) / 10;
      }
      return {
        ...artisan,
        distanceKm,
      };
    });

    // If radiusKm is specified and coordinates are provided, filter within radius
    if (lat != null && lng != null && radiusKm != null) {
      results = results.filter((a) => a.distanceKm != null && a.distanceKm <= radiusKm);
    }

    // If GPS coordinates are provided, sort closest first (and with equal distance/nulls by rating)
    if (lat != null && lng != null) {
      results.sort((a, b) => {
        if (a.distanceKm != null && b.distanceKm != null) {
          return a.distanceKm - b.distanceKm;
        }
        if (a.distanceKm != null) return -1;
        if (b.distanceKm != null) return 1;
        return (b.averageRating ?? 0) - (a.averageRating ?? 0);
      });
    }

    await this.redis.set(cacheKey, results, NEARBY_TTL);
    return results;
  }

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * (Math.PI / 180)) *
        Math.cos(lat2 * (Math.PI / 180)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  // ─── Single artisan public profile ───────────────────────────────────────

  async findById(artisanId: string) {
    const cacheKey = this.byIdKey(artisanId);
    const cached = await this.redis.get<any>(cacheKey);
    if (cached) return cached;

    const artisan = await this.prisma.artisan.findUnique({
      where: { id: artisanId },
      include: ARTISAN_INCLUDE,
    });
    if (!artisan) throw new NotFoundException(`Artisan ${artisanId} not found`);
    await this.redis.set(cacheKey, artisan, PROFILE_TTL);
    return artisan;
  }

  // ─── Submit verification document ────────────────────────────────────────

  async submitVerificationDocument(
    userId: string,
    type: VerificationDocumentType,
    fileUrl: string,
  ) {
    const artisan = await this.getProfile(userId);
    return this.prisma.verificationDocument.create({
      data: { artisanId: artisan.id, type, fileUrl },
    });
  }

  // ─── Associate category ───────────────────────────────────────────────────

  async associateCategory(userId: string, categoryId: string) {
    const artisan = await this.getProfile(userId);

    // Upsert to avoid duplicate key errors
    return this.prisma.artisanCategory.upsert({
      where: { artisanId_categoryId: { artisanId: artisan.id, categoryId } },
      create: { artisanId: artisan.id, categoryId },
      update: {},
    });
  }

  // ─── Remove category ──────────────────────────────────────────────────────

  async removeCategory(userId: string, categoryId: string) {
    const artisan = await this.getProfile(userId);
    return this.prisma.artisanCategory.deleteMany({
      where: { artisanId: artisan.id, categoryId },
    });
  }
}
