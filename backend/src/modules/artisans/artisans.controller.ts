import { Controller, Get, Patch, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ArtisansService } from './artisans.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';
import { VerificationDocumentType } from '@prisma/client';

@ApiTags('Artisans')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller('artisans')
export class ArtisansController {
  constructor(private readonly artisansService: ArtisansService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Get current artisan profile' })
  getProfile(@CurrentUser() user: AuthenticatedUser) {
    return this.artisansService.getProfile(user.id);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update current artisan profile' })
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { businessName?: string; fullName?: string; bio?: string; experience?: string; yearsExperience?: number; hourlyRate?: number; profilePhoto?: string; availabilityStatus?: any; latitude?: number; longitude?: number },
  ) {
    return this.artisansService.updateProfile(user.id, body);
  }

  @Post('verify')
  @ApiOperation({ summary: 'Submit verification document' })
  submitDocument(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { type: VerificationDocumentType; fileUrl: string },
  ) {
    return this.artisansService.submitVerificationDocument(user.id, body.type, body.fileUrl);
  }

  @Post('categories')
  @ApiOperation({ summary: 'Associate category to artisan' })
  addCategory(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { categoryId: string },
  ) {
    return this.artisansService.associateCategory(user.id, body.categoryId);
  }
}
