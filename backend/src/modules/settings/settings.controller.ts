import { Controller, Get, Patch, Body, UseGuards } from '@nestjs/common';
import { SettingsService } from './settings.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('settings')
@UseGuards(SupabaseAuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get('commission')
  async getCommission() {
    const percentage = await this.settingsService.getCommissionPercentage();
    return { admin_commission_percentage: percentage };
  }

  @Patch('commission')
  async updateCommission(@Body('percentage') percentage: number) {
    await this.settingsService.setSetting('admin_commission_percentage', percentage.toString());
    return { success: true };
  }
}
