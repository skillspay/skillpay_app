import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { VerificationDocumentType } from '@prisma/client';

@Injectable()
export class ArtisansService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    const profile = await this.prisma.artisan.findUnique({
      where: { userId },
      include: { user: true, categories: { include: { category: true } }, verificationDocuments: true },
    });
    if (!profile) {
      throw new NotFoundException(`Artisan profile not found`);
    }
    return profile;
  }

  async updateProfile(userId: string, data: { businessName?: string; fullName?: string; bio?: string; experience?: string; yearsExperience?: number; hourlyRate?: number; profilePhoto?: string; availabilityStatus?: any; latitude?: number; longitude?: number }) {
    await this.getProfile(userId); // checks if exists
    return this.prisma.artisan.update({
      where: { userId },
      data,
    });
  }

  async submitVerificationDocument(userId: string, type: VerificationDocumentType, fileUrl: string) {
    const artisan = await this.getProfile(userId);
    return this.prisma.verificationDocument.create({
      data: {
        artisanId: artisan.id,
        type,
        fileUrl,
      },
    });
  }

  async associateCategory(userId: string, categoryId: string) {
    const artisan = await this.getProfile(userId);
    return this.prisma.artisanCategory.create({
      data: {
        artisanId: artisan.id,
        categoryId,
      },
    });
  }
}
