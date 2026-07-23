import {
  Controller,
  Post,
  Patch,
  Get,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  Req,
  UnauthorizedException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { Request } from 'express';
import { createClient } from '@supabase/supabase-js';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { RegisterDto, UpdateFcmTokenDto } from './dto/register.dto';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Auth')
@ApiBearerAuth('supabase-jwt')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly config: ConfigService,
  ) {}

  /**
   * POST /auth/register
   *
   * Marked @Public() — bypasses the DB user lookup in SupabaseAuthGuard
   * because the user row doesn't exist yet on first call.
   * We still validate the Supabase JWT manually to get the supabaseUserId.
   * This endpoint is idempotent: safe to call on every login.
   */
  @Post('register')
  @Public()
  @ApiOperation({ summary: 'Upsert user in DB (called on first login after email confirmation)' })
  @ApiResponse({ status: 201, description: 'User registered/found' })
  async register(@Req() req: Request, @Body() dto: RegisterDto) {
    // Manually validate the JWT since guard skips DB lookup for @Public routes
    const token = this.extractToken(req);
    if (!token) throw new UnauthorizedException('No authorization token provided');

    const supabase = createClient(
      this.config.get<string>('supabase.url')!,
      this.config.get<string>('supabase.serviceRoleKey')!,
    );
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) throw new UnauthorizedException('Invalid or expired token');

    return this.authService.register(data.user.id, dto);
  }

  /**
   * POST /auth/login
   * Updates last_login. Requires a valid session (user must exist in DB).
   */
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Record login timestamp' })
  async login(@CurrentUser() user: AuthenticatedUser) {
    await this.authService.login(user.supabaseUserId);
    return { message: 'Login recorded' };
  }

  /**
   * GET /auth/me
   * Returns the current user's full profile.
   */
  @Get('me')
  @ApiOperation({ summary: 'Get current authenticated user' })
  async getMe(@CurrentUser() user: AuthenticatedUser) {
    return this.authService.getMe(user.id);
  }

  /**
   * PATCH /auth/fcm-token
   * Saves the FCM push notification token.
   */
  @Patch('fcm-token')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Save FCM push notification token' })
  async updateFcmToken(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateFcmTokenDto,
  ) {
    await this.authService.updateFcmToken(user.id, dto);
    return { message: 'FCM token updated' };
  }

  // ─── Helper ──────────────────────────────────────────────────────────────

  private extractToken(req: Request): string | null {
    const auth = req.headers['authorization'];
    if (!auth) return null;
    const [scheme, token] = auth.split(' ');
    return scheme?.toLowerCase() === 'bearer' ? token : null;
  }
}
