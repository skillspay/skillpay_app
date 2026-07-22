import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { PaginationDto, paginate } from '../../common/dto/pagination.dto';
import { Role, UserStatus } from '@prisma/client';

const USER_SELECT = {
  id: true,
  email: true,
  phone: true,
  role: true,
  status: true,
  isVerified: true,
  lastLogin: true,
  createdAt: true,
  updatedAt: true,
  homeowner: {
    select: { id: true, fullName: true, profilePhoto: true, defaultAddress: true },
  },
  artisan: {
    select: {
      id: true,
      fullName: true,
      profilePhoto: true,
      verificationStatus: true,
      availabilityStatus: true,
      averageRating: true,
      completedJobs: true,
    },
  },
};

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(pagination: PaginationDto, role?: Role, status?: UserStatus) {
    const where = {
      ...(role ? { role } : {}),
      ...(status ? { status } : {}),
    };

    const [data, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: USER_SELECT,
        orderBy: { createdAt: 'desc' },
        skip: pagination.skip,
        take: pagination.limit,
      }),
      this.prisma.user.count({ where }),
    ]);

    return paginate(data, total, pagination.page ?? 1, pagination.limit ?? 20);
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: USER_SELECT,
    });
    if (!user) throw new NotFoundException(`User ${id} not found`);
    return user;
  }

  async update(id: string, dto: UpdateUserDto) {
    await this.findOne(id); // throws if not found
    return this.prisma.user.update({
      where: { id },
      data: dto,
      select: USER_SELECT,
    });
  }

  async suspend(id: string) {
    await this.findOne(id);
    return this.prisma.user.update({
      where: { id },
      data: { status: UserStatus.SUSPENDED },
      select: { id: true, email: true, status: true },
    });
  }

  async ban(id: string) {
    await this.findOne(id);
    return this.prisma.user.update({
      where: { id },
      data: { status: UserStatus.BANNED },
      select: { id: true, email: true, status: true },
    });
  }

  async activate(id: string) {
    await this.findOne(id);
    return this.prisma.user.update({
      where: { id },
      data: { status: UserStatus.ACTIVE },
      select: { id: true, email: true, status: true },
    });
  }

  async getStats() {
    const [total, homeowners, artisans, admins, active, suspended, banned] =
      await Promise.all([
        this.prisma.user.count(),
        this.prisma.user.count({ where: { role: Role.HOMEOWNER } }),
        this.prisma.user.count({ where: { role: Role.ARTISAN } }),
        this.prisma.user.count({
          where: { role: { in: [Role.ADMIN, Role.SUPER_ADMIN] } },
        }),
        this.prisma.user.count({ where: { status: UserStatus.ACTIVE } }),
        this.prisma.user.count({ where: { status: UserStatus.SUSPENDED } }),
        this.prisma.user.count({ where: { status: UserStatus.BANNED } }),
      ]);

    return { total, homeowners, artisans, admins, active, suspended, banned };
  }
}
