import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationType } from '@prisma/client';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { MailService } from '../mail/mail.service';

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly mailService: MailService,
  ) {}

  onModuleInit() {
    const projectId = this.config.get<string>('firebase.projectId');
    const clientEmail = this.config.get<string>('firebase.clientEmail');
    let privateKey = this.config.get<string>('firebase.privateKey');

    if (projectId && clientEmail && privateKey) {
      if (getApps().length === 0) {
        // Robustly parse the private key to handle Railway/Docker environment variables
        // which often mangle newlines or strip them or turn them into spaces.
        const keyBody = privateKey
          .replace(/-----BEGIN PRIVATE KEY-----/g, '')
          .replace(/-----END PRIVATE KEY-----/g, '')
          .replace(/\\n/g, '')
          .replace(/"/g, '')
          .replace(/\s+/g, ''); // remove all whitespace, spaces, actual newlines
          
        // Reconstruct the key with proper PEM formatting
        // OpenSSL doesn't strictly need 64-char lines for the body, but it MUST have the headers separated by newlines
        privateKey = `-----BEGIN PRIVATE KEY-----\n${keyBody}\n-----END PRIVATE KEY-----\n`;
        
        initializeApp({
          credential: cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
        this.logger.log('Firebase Admin SDK initialized successfully.');
      }
    } else {
      this.logger.warn('Firebase Admin SDK not initialized. Missing environment variables.');
    }
  }

  async createNotification(userId: string, title: string, body: string, type: NotificationType = 'GENERAL', metadata?: any) {
    // 1. Create DB Record
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        title,
        body,
        type,
        metadata,
      },
    });

    // 2. Try to send FCM push if Firebase is initialized
    if (getApps().length > 0) {
      try {
        const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { email: true, fcmToken: true }});
        
        // Push Notification
        if (user?.fcmToken) {
          await getMessaging().send({
            token: user.fcmToken,
            notification: {
              title,
              body,
            },
            data: {
              type,
              notificationId: notification.id,
              ...(metadata ? { metadata: JSON.stringify(metadata) } : {}),
            },
          });
          this.logger.log(`FCM notification sent to user ${userId}`);
        }

        // Email Alert for important notification types
        if (user?.email && ['APPLICATION', 'BOOKING', 'PAYMENT', 'VERIFICATION'].includes(type)) {
           // We fire and forget the email sending so it doesn't block the request
           this.mailService.sendNotificationEmail(user.email, title, body).catch(e => {
             this.logger.error(`Error sending email to ${user.email}`, e);
           });
        }
      } catch (e) {
        this.logger.error(`Failed to send alerts to user ${userId}:`, e);
      }
    } else {
      // Fallback if Firebase not initialized: still try to send email
      try {
        const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { email: true }});
        if (user?.email && ['APPLICATION', 'BOOKING', 'PAYMENT', 'VERIFICATION'].includes(type)) {
           this.mailService.sendNotificationEmail(user.email, title, body).catch(e => {
             this.logger.error(`Error sending email to ${user.email}`, e);
           });
        }
      } catch (e) {
        this.logger.error(`Failed to send email to user ${userId}:`, e);
      }
    }

    return notification;
  }

  async getForUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
  }

  async markAsRead(id: string) {
    return this.prisma.notification.update({
      where: { id },
      data: { read: true },
    });
  }
}
