import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  healthCheck(): Record<string, string> {
    return {
      status: 'ok',
      service: 'Skillpay API',
      timestamp: new Date().toISOString(),
    };
  }
}
