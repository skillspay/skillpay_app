import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class HomeownersService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── Get or auto-create profile ──────────────────────────────────────────

  async getProfile(userId: string) {
    let profile = await this.prisma.homeowner.findUnique({
      where: { userId },
      include: {
        user: { select: { id: true, email: true, phone: true, role: true } },
        addresses: { orderBy: { isDefault: 'desc' } },
      },
    });

    if (!profile) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, email: true },
      });
      if (!user) throw new NotFoundException('User not found');

      profile = await this.prisma.homeowner.create({
        data: {
          userId,
          fullName: user.email.split('@')[0],
        },
        include: {
          user: { select: { id: true, email: true, phone: true, role: true } },
          addresses: true,
        },
      });
    }

    return profile;
  }

  // ─── Initial setup (called after email confirmation) ─────────────────────

  async setup(
    userId: string,
    data: {
      fullName: string;
      phone?: string;
      defaultAddress?: string;
      latitude?: number;
      longitude?: number;
    },
  ) {
    // Upsert homeowner row
    const existing = await this.prisma.homeowner.findUnique({
      where: { userId },
    });

    const homeowner = existing
      ? await this.prisma.homeowner.update({
          where: { userId },
          data: {
            fullName: data.fullName,
            defaultAddress: data.defaultAddress,
            latitude: data.latitude,
            longitude: data.longitude,
          },
        })
      : await this.prisma.homeowner.create({
          data: {
            userId,
            fullName: data.fullName,
            defaultAddress: data.defaultAddress,
            latitude: data.latitude,
            longitude: data.longitude,
          },
        });

    // Update phone on the user row
    if (data.phone) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { phone: data.phone },
      });
    }

    return homeowner;
  }

  // ─── Update profile ───────────────────────────────────────────────────────

  async updateProfile(
    userId: string,
    data: {
      fullName?: string;
      gender?: string;
      dob?: string;
      profilePhoto?: string;
      defaultAddress?: string;
      latitude?: number;
      longitude?: number;
      preferredContact?: string;
    },
  ) {
    await this.getProfile(userId); // auto-creates if missing

    const { preferredContact, dob, ...rest } = data;

    return this.prisma.homeowner.update({
      where: { userId },
      data: {
        ...rest,
        ...(dob ? { dob: new Date(dob) } : {}),
      },
      include: {
        user: { select: { id: true, email: true, phone: true } },
        addresses: true,
      },
    });
  }

  // ─── Addresses ────────────────────────────────────────────────────────────

  async getAddresses(userId: string) {
    const homeowner = await this.getProfile(userId);
    return this.prisma.address.findMany({
      where: { userId: homeowner.userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
  }

  async addAddress(
    userId: string,
    data: {
      label: string;
      address: string;
      latitude?: number;
      longitude?: number;
      isDefault?: boolean;
    },
  ) {
    // If this is default, clear others
    if (data.isDefault) {
      await this.prisma.address.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    return this.prisma.address.create({
      data: { userId, ...data },
    });
  }

  async updateAddress(
    userId: string,
    addressId: string,
    data: {
      label?: string;
      address?: string;
      latitude?: number;
      longitude?: number;
      isDefault?: boolean;
    },
  ) {
    const addr = await this.prisma.address.findUnique({
      where: { id: addressId },
    });
    if (!addr) throw new NotFoundException(`Address ${addressId} not found`);
    if (addr.userId !== userId) throw new ForbiddenException('Not your address');

    if (data.isDefault) {
      await this.prisma.address.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    return this.prisma.address.update({
      where: { id: addressId },
      data,
    });
  }

  async setDefaultAddress(userId: string, addressId: string) {
    const addr = await this.prisma.address.findUnique({
      where: { id: addressId },
    });
    if (!addr) throw new NotFoundException(`Address ${addressId} not found`);
    if (addr.userId !== userId) throw new ForbiddenException('Not your address');

    await this.prisma.address.updateMany({
      where: { userId },
      data: { isDefault: false },
    });

    return this.prisma.address.update({
      where: { id: addressId },
      data: { isDefault: true },
    });
  }

  async deleteAddress(userId: string, addressId: string) {
    const addr = await this.prisma.address.findUnique({
      where: { id: addressId },
    });
    if (!addr) throw new NotFoundException(`Address ${addressId} not found`);
    if (addr.userId !== userId) throw new ForbiddenException('Not your address');

    return this.prisma.address.delete({ where: { id: addressId } });
  }
}
