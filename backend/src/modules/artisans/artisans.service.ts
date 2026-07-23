import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { VerificationDocumentType } from '@prisma/client';

const ARTISAN_INCLUDE = {
  user: { select: { id: true, email: true, phone: true } },
  categories: { include: { category: true } },
  verificationDocuments: true,
};

@Injectable()
export class ArtisansService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── Get or create profile ────────────────────────────────────────────────

  async getProfile(userId: string) {
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

    return profile;
  }

  // ─── Update profile ───────────────────────────────────────────────────────

  async updateProfile(
    userId: string,
    data: {
      businessName?: string;
      fullName?: string;
      bio?: string;
      experience?: string;
      yearsExperience?: number;
      hourlyRate?: number;
      profilePhoto?: string;
      availabilityStatus?: any;
      latitude?: number;
      longitude?: number;
    },
  ) {
    // Ensure profile exists
    await this.getProfile(userId);

    return this.prisma.artisan.update({
      where: { userId },
      data,
      include: ARTISAN_INCLUDE,
    });
  }

  // ─── Nearby artisans ──────────────────────────────────────────────────────

  async findNearby(filters: {
    categoryId?: string;
    lat?: number;
    lng?: number;
    radiusKm?: number;
    limit?: number;
    search?: string;
  }) {
    const { categoryId, limit, search } = filters;

    return this.prisma.artisan.findMany({
      where: {
        availabilityStatus: 'AVAILABLE',
        ...(categoryId
          ? { categories: { some: { categoryId } } }
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
      take: limit ? Number(limit) : 20,
    });
  }

  // ─── Single artisan public profile ───────────────────────────────────────

  async findById(artisanId: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { id: artisanId },
      include: ARTISAN_INCLUDE,
    });
    if (!artisan) throw new NotFoundException(`Artisan ${artisanId} not found`);
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
