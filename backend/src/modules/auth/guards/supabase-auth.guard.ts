import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { IS_PUBLIC_KEY } from '../../../common/decorators/public.decorator';
import { PrismaService } from '../../../prisma/prisma.service';
import { RequestWithUser } from '../../../common/interfaces/request-with-user.interface';

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  private readonly logger = new Logger(SupabaseAuthGuard.name);
  private readonly supabase: SupabaseClient;

  constructor(
    private readonly reflector: Reflector,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    const url = this.config.get<string>('supabase.url') ?? '';
    const key = this.config.get<string>('supabase.serviceRoleKey') ?? '';
    if (!url || !key) {
      this.logger.error('SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set!');
    }
    this.supabase = createClient(url || 'https://placeholder.supabase.co', key || 'placeholder');
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Allow @Public() routes through without a token
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<RequestWithUser>();
    const token = this.extractToken(request);

    if (!token) {
      throw new UnauthorizedException('No authorization token provided');
    }

    // Validate JWT with Supabase
    const { data, error } = await this.supabase.auth.getUser(token);

    if (error || !data.user) {
      this.logger.warn(`Invalid Supabase token: ${error?.message}`);
      throw new UnauthorizedException('Invalid or expired token');
    }

    // Look up the user in our own DB to get role / status
    const dbUser = await this.prisma.user.findUnique({
      where: { supabaseUserId: data.user.id },
      select: {
        id: true,
        supabaseUserId: true,
        email: true,
        role: true,
        status: true,
        isVerified: true,
      },
    });

    if (!dbUser) {
      throw new UnauthorizedException(
        'User not found. Please complete registration.',
      );
    }

    if (dbUser.status === 'BANNED' || dbUser.status === 'SUSPENDED') {
      throw new UnauthorizedException(
        `Account is ${dbUser.status.toLowerCase()}. Contact support.`,
      );
    }

    // Attach the user to the request for downstream use
    request.user = dbUser;
    return true;
  }

  private extractToken(request: any): string | null {
    const authHeader = request.headers?.authorization || request.headers?.['authorization'];
    if (!authHeader) return null;
    const [scheme, token] = authHeader.split(' ');
    if (scheme?.toLowerCase() !== 'bearer' || !token) return null;
    return token;
  }
}
