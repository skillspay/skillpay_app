import {
  Controller,
  Get,
  Patch,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ArtisansService } from './artisans.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';
import { VerificationDocumentType } from '@prisma/client';

@ApiTags('Artisans')
@ApiBearerAuth('supabase-jwt')
@Controller('artisans')
export class ArtisansController {
  constructor(private readonly artisansService: ArtisansService) {}

  // Flutter (workers): GET /artisans/nearby
  @Get('nearby')
  @ApiOperation({ summary: 'Find nearby available artisans' })
  findNearby(
    @Query('lat') lat?: number,
    @Query('lng') lng?: number,
    @Query('categoryId') categoryId?: string,
    @Query('radiusKm') radiusKm?: number,
    @Query('limit') limit?: number,
  ) {
    return this.artisansService.findNearby({ lat, lng, categoryId, radiusKm, limit });
  }

  // Flutter (workers): GET /artisans/profile
  @Get('profile')
  @ApiOperation({ summary: 'Get current artisan profile' })
  getProfile(@CurrentUser() user: AuthenticatedUser) {
    return this.artisansService.getProfile(user.id);
  }

  // Flutter (customer): GET /artisans  (search)
  @Get()
  @ApiOperation({ summary: 'Search artisans' })
  search(@Query('search') search?: string, @Query('limit') limit?: number) {
    return this.artisansService.findNearby({ search, limit });
  }

  // Flutter (customer): GET /artisans/:id
  @Get(':id')
  @ApiOperation({ summary: 'Get artisan public profile by ID' })
  findOne(@Param('id') id: string) {
    return this.artisansService.findById(id);
  }

  // Flutter (workers): PATCH /artisans/profile
  @Patch('profile')
  @ApiOperation({ summary: 'Update artisan profile' })
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body()
    body: {
      businessName?: string;
      fullName?: string;
      bio?: string;
      experience?: string;
      yearsExperience?: number;
      hourlyRate?: number;
      profilePhoto?: string;
      availabilityStatus?: string;
      latitude?: number;
      longitude?: number;
    },
  ) {
    return this.artisansService.updateProfile(user.id, body);
  }

  // Flutter (workers): POST /artisans/categories
  @Post('categories')
  @ApiOperation({ summary: 'Add a service category' })
  addCategory(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { categoryId: string },
  ) {
    return this.artisansService.associateCategory(user.id, body.categoryId);
  }

  // Flutter (workers): DELETE /artisans/categories/:id
  @Delete('categories/:categoryId')
  @ApiOperation({ summary: 'Remove a service category' })
  removeCategory(
    @CurrentUser() user: AuthenticatedUser,
    @Param('categoryId') categoryId: string,
  ) {
    return this.artisansService.removeCategory(user.id, categoryId);
  }

  // Flutter (workers): POST /artisans/verify
  @Post('verify')
  @ApiOperation({ summary: 'Submit verification document' })
  submitDocument(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { type: VerificationDocumentType; fileUrl: string },
  ) {
    return this.artisansService.submitVerificationDocument(
      user.id,
      body.type,
      body.fileUrl,
    );
  }
}
