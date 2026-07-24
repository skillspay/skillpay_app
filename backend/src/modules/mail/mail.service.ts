import { Injectable, Logger } from '@nestjs/common';
import { MailerService } from '@nestjs-modules/mailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(private readonly mailerService: MailerService) {}

  async sendNotificationEmail(to: string, title: string, body: string, actionUrl?: string) {
    try {
      await this.mailerService.sendMail({
        to,
        subject: title,
        template: './notification', // relative to dir specified in module
        context: {
          title,
          body,
          actionUrl,
        },
      });
      this.logger.log(`Email sent successfully to ${to}`);
    } catch (error) {
      this.logger.error(`Failed to send email to ${to}`, error);
    }
  }
}
