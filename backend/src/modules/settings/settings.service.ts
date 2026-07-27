import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SettingsService {
  constructor(private prisma: PrismaService) {}

  async getSetting(key: string, defaultValue: string = ''): Promise<string> {
    const setting = await this.prisma.systemSetting.findUnique({ where: { key } });
    if (!setting) {
      await this.prisma.systemSetting.create({ data: { key, value: defaultValue } });
      return defaultValue;
    }
    return setting.value;
  }

  async setSetting(key: string, value: string): Promise<void> {
    await this.prisma.systemSetting.upsert({
      where: { key },
      update: { value },
      create: { key, value },
    });
  }

  async getCommissionPercentage(): Promise<number> {
    const val = await this.getSetting('admin_commission_percentage', '10');
    return parseFloat(val) || 10;
  }
}
