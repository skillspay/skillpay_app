import {
  Injectable,
  ConflictException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterDto, UpdateFcmTokenDto } from './dto/register.dto';
import { Role } from '@prisma/client';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Called by Flutter app after Supabase sign-up.
   * Creates (or finds) the User row in our Postgres DB.
   * supabaseUserId comes from the validated JWT in the guard.
   */
  async register(
    supabaseUserId: string,
    dto: RegisterDto,
  ): Promise<{ id: string; email: string; role: Role }> {
    const existing = await this.prisma.user.findUnique({
      where: { supabaseUserId },
    });

    if (existing) {
      // Idempotent — return existing user (re-registration after reinstall)
      return { id: existing.id, email: existing.email, role: existing.role };
    }

    const emailTaken = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (emailTaken) {
      throw new ConflictException('Email already registered');
    }

    const user = await this.prisma.user.create({
      data: {
        supabaseUserId,
        email: dto.email,
        phone: dto.phone,
        role: dto.role ?? Role.HOMEOWNER,
      },
      select: { id: true, email: true, role: true },
    });

    this.logger.log(`New user registered: ${user.email} (${user.role})`);
    return user;
  }

  /**
   * Called by Flutter app on every sign-in.
   * Updates last_login timestamp.
   */
  async login(supabaseUserId: string): Promise<void> {
    await this.prisma.user.update({
      where: { supabaseUserId },
      data: { lastLogin: new Date() },
    });
  }

  /**
   * Saves the FCM push token for the current user.
   */
  async updateFcmToken(userId: string, dto: UpdateFcmTokenDto): Promise<void> {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken: dto.fcmToken },
    });
  }

  /**
   * Returns the currently authenticated user's profile.
   */
  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        phone: true,
        role: true,
        status: true,
        isVerified: true,
        lastLogin: true,
        createdAt: true,
        homeowner: {
          select: {
            id: true,
            fullName: true,
            profilePhoto: true,
            defaultAddress: true,
          },
        },
        artisan: {
          select: {
            id: true,
            fullName: true,
            profilePhoto: true,
            verificationStatus: true,
            availabilityStatus: true,
          },
        },
      },
    });

    if (!user) throw new NotFoundException('User not found');
    return user;
  }
}
