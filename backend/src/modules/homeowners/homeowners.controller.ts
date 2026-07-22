import { Controller, Get, Patch, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { HomeownersService } from './homeowners.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Homeowners')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller('homeowners')
export class HomeownersController {
  constructor(private readonly homeownersService: HomeownersService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Get current homeowner profile' })
  getProfile(@CurrentUser() user: AuthenticatedUser) {
    return this.homeownersService.getProfile(user.id);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update current homeowner profile' })
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { fullName?: string; gender?: string; dob?: Date; profilePhoto?: string; defaultAddress?: string; latitude?: number; longitude?: number },
  ) {
    return this.homeownersService.updateProfile(user.id, body);
  }
}
