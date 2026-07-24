import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
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

  // Flutter: GET /homeowners/profile
  @Get('profile')
  @ApiOperation({ summary: 'Get homeowner profile' })
  getProfile(@CurrentUser() user: AuthenticatedUser) {
    return this.homeownersService.getProfile(user.id);
  }

  // Flutter: POST /homeowners/profile/setup  (called after OTP confirmation)
  @Post('profile/setup')
  @ApiOperation({ summary: 'Initial profile setup after email confirmation' })
  setup(
    @CurrentUser() user: AuthenticatedUser,
    @Body()
    body: {
      fullName: string;
      phone?: string;
      defaultAddress?: string;
      latitude?: number;
      longitude?: number;
    },
  ) {
    return this.homeownersService.setup(user.id, body);
  }

  // Flutter: PATCH /homeowners/profile
  @Patch('profile')
  @ApiOperation({ summary: 'Update homeowner profile' })
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body()
    body: {
      fullName?: string;
      phone?: string;
      gender?: string;
      dob?: string;
      profilePhoto?: string;
      defaultAddress?: string;
      latitude?: number;
      longitude?: number;
      preferredContact?: string;
    },
  ) {
    return this.homeownersService.updateProfile(user.id, body);
  }

  // Flutter: GET /homeowners/addresses
  @Get('addresses')
  @ApiOperation({ summary: 'List saved addresses' })
  getAddresses(@CurrentUser() user: AuthenticatedUser) {
    return this.homeownersService.getAddresses(user.id);
  }

  // Flutter: POST /homeowners/addresses
  @Post('addresses')
  @ApiOperation({ summary: 'Add a saved address' })
  addAddress(
    @CurrentUser() user: AuthenticatedUser,
    @Body()
    body: {
      label: string;
      address: string;
      latitude?: number;
      longitude?: number;
      isDefault?: boolean;
    },
  ) {
    return this.homeownersService.addAddress(user.id, body);
  }

  // Flutter: PATCH /homeowners/addresses/:id
  @Patch('addresses/:id')
  @ApiOperation({ summary: 'Update a saved address' })
  updateAddress(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body()
    body: {
      label?: string;
      address?: string;
      latitude?: number;
      longitude?: number;
      isDefault?: boolean;
    },
  ) {
    return this.homeownersService.updateAddress(user.id, id, body);
  }

  // Flutter: PATCH /homeowners/addresses/:id/set-default
  @Patch('addresses/:id/set-default')
  @ApiOperation({ summary: 'Set address as default' })
  setDefault(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.homeownersService.setDefaultAddress(user.id, id);
  }

  // Flutter: DELETE /homeowners/addresses/:id
  @Delete('addresses/:id')
  @ApiOperation({ summary: 'Delete a saved address' })
  deleteAddress(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.homeownersService.deleteAddress(user.id, id);
  }
}
