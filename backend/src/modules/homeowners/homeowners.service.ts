import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class HomeownersService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    const profile = await this.prisma.homeowner.findUnique({
      where: { userId },
      include: { user: true },
    });
    if (!profile) {
      throw new NotFoundException(`Homeowner profile not found`);
    }
    return profile;
  }

  async updateProfile(userId: string, data: { fullName?: string; gender?: string; dob?: Date; profilePhoto?: string; defaultAddress?: string; latitude?: number; longitude?: number }) {
    await this.getProfile(userId); // checks if exists
    return this.prisma.homeowner.update({
      where: { userId },
      data,
    });
  }
}
