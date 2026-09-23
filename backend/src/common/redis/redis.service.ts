import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis | null = null;
  private isConnected = false;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    const redisUrl =
      this.configService.get<string>('redis.url') || process.env.REDIS_URL;

    if (!redisUrl) {
      this.logger.log(
        'REDIS_URL not configured. Operating in direct database fallback mode.',
      );
      return;
    }

    try {
      this.client = new Redis(redisUrl, {
        retryStrategy: (times) => {
          if (times > 10) {
            this.logger.warn('Redis retry limit exceeded. Suspending retries.');
            return null;
          }
          return Math.min(times * 150, 3000);
        },
        maxRetriesPerRequest: 2,
        connectTimeout: 8000,
        lazyConnect: false,
      });

      this.client.on('connect', () => {
        this.isConnected = true;
        this.logger.log('Successfully connected to Redis instance.');
      });

      this.client.on('ready', () => {
        this.isConnected = true;
      });

      this.client.on('error', (err) => {
        this.isConnected = false;
        this.logger.warn(`Redis connection error: ${err.message}`);
      });

      this.client.on('close', () => {
        this.isConnected = false;
      });
    } catch (err: any) {
      this.logger.warn(
        `Failed to initialize Redis client: ${err?.message || err}. Falling back to DB.`,
      );
      this.client = null;
    }
  }

  async onModuleDestroy() {
    if (this.client) {
      try {
        await this.client.quit();
      } catch (_) {
        this.client.disconnect();
      }
    }
  }

  get isReady(): boolean {
    return this.isConnected && this.client !== null;
  }

  /**
   * Retrieve cached value and parse from JSON
   */
  async get<T>(key: string): Promise<T | null> {
    if (!this.isReady || !this.client) return null;

    try {
      const data = await this.client.get(key);
      if (!data) return null;
      return JSON.parse(data) as T;
    } catch (err: any) {
      this.logger.warn(`Error reading key "${key}" from Redis: ${err.message}`);
      return null;
    }
  }

  /**
   * Cache a value as JSON with optional TTL in seconds
   */
  async set(key: string, value: any, ttlSeconds?: number): Promise<void> {
    if (!this.isReady || !this.client) return;

    try {
      const serialized = JSON.stringify(value);
      if (ttlSeconds && ttlSeconds > 0) {
        await this.client.set(key, serialized, 'EX', ttlSeconds);
      } else {
        await this.client.set(key, serialized);
      }
    } catch (err: any) {
      this.logger.warn(`Error writing key "${key}" to Redis: ${err.message}`);
    }
  }

  /**
   * Delete an exact key
   */
  async del(key: string): Promise<void> {
    if (!this.isReady || !this.client) return;

    try {
      await this.client.del(key);
    } catch (err: any) {
      this.logger.warn(`Error deleting key "${key}" from Redis: ${err.message}`);
    }
  }

  /**
   * Delete all keys matching a pattern using SCAN stream (non-blocking)
   */
  async delByPattern(pattern: string): Promise<void> {
    if (!this.isReady || !this.client) return;

    try {
      const stream = this.client.scanStream({
        match: pattern,
        count: 50,
      });

      stream.on('data', async (keys: string[]) => {
        if (keys.length && this.client) {
          stream.pause();
          try {
            await this.client.del(...keys);
          } finally {
            stream.resume();
          }
        }
      });

      stream.on('error', (err) => {
        this.logger.warn(
          `Error scanning keys for pattern "${pattern}": ${err.message}`,
        );
      });
    } catch (err: any) {
      this.logger.warn(
        `Error deleting pattern "${pattern}" from Redis: ${err.message}`,
      );
    }
  }
}
