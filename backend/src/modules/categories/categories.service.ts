import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RedisService } from '../../common/redis/redis.service';

const CACHE_TTL = 600; // 10 minutes
const KEY_ALL = 'categories:all';
const KEY_ACTIVE = 'categories:active';

@Injectable()
export class CategoriesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async findAll() {
    const cached = await this.redis.get<any[]>(KEY_ALL);
    if (cached) return cached;

    const data = await this.prisma.category.findMany({
      orderBy: { name: 'asc' },
    });
    await this.redis.set(KEY_ALL, data, CACHE_TTL);
    return data;
  }

  async findActive() {
    const cached = await this.redis.get<any[]>(KEY_ACTIVE);
    if (cached) return cached;

    const data = await this.prisma.category.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
    await this.redis.set(KEY_ACTIVE, data, CACHE_TTL);
    return data;
  }

  async create(data: { name: string; icon?: string; image?: string; description?: string }) {
    const result = await this.prisma.category.create({
      data: {
        name: data.name,
        icon: data.icon,
        image: data.image,
        description: data.description,
      },
    });
    // Invalidate both caches
    await this.redis.del(KEY_ALL);
    await this.redis.del(KEY_ACTIVE);
    return result;
  }

  async update(id: string, data: { name?: string; icon?: string; image?: string; description?: string; isActive?: boolean }) {
    const category = await this.prisma.category.findUnique({ where: { id } });
    if (!category) {
      throw new NotFoundException(`Category with ID ${id} not found`);
    }

    const result = await this.prisma.category.update({
      where: { id },
      data,
    });
    // Invalidate both caches
    await this.redis.del(KEY_ALL);
    await this.redis.del(KEY_ACTIVE);
    return result;
  }
}
