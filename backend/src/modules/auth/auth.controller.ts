import {
  Controller,
  Post,
  Patch,
  Get,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterDto, UpdateFcmTokenDto } from './dto/register.dto';
import { SupabaseAuthGuard } from './guards/supabase-auth.guard';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Auth')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * POST /auth/register
   * Called after Supabase sign-up. Creates the DB user row.
   * Still requires a valid Supabase JWT (user is signed in after signUp).
   */
  @Post('register')
  @ApiOperation({ summary: 'Register user in DB after Supabase sign-up' })
  @ApiResponse({ status: 201, description: 'User registered successfully' })
  async register(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RegisterDto,
  ) {
    return this.authService.register(user.supabaseUserId, dto);
  }

  /**
   * POST /auth/login
   * Called on every sign-in. Updates last_login.
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
}
