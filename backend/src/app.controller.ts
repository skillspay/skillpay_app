import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('Health')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  @ApiOperation({ summary: 'Health check' })
  healthCheck() {
    return this.appService.healthCheck();
  }

  @Get('debug-config')
  @ApiOperation({ summary: 'Show which Supabase project is configured (non-sensitive)' })
  debugConfig() {
    const url = process.env.SUPABASE_URL ?? 'NOT SET';
    const hasServiceKey = !!(process.env.SUPABASE_SERVICE_ROLE_KEY);
    const dbUrl = process.env.DATABASE_URL
      ? process.env.DATABASE_URL.replace(/:[^:@]+@/, ':***@')
      : 'NOT SET';
    return {
      supabaseUrl: url,
      hasServiceRoleKey: hasServiceKey,
      nodeEnv: process.env.NODE_ENV,
      databaseUrl: dbUrl,
    };
  }
}
