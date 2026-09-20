import { Injectable, NotFoundException, Inject, forwardRef } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ApplicationStatus } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { ChatGateway } from './chat.gateway';

@Injectable()
export class ChatService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    @Inject(forwardRef(() => ChatGateway))
    private readonly chatGateway: ChatGateway,
  ) {}

  // ─── Get or create conversation ───────────────────────────────────────────

  async getOrCreateConversation(jobId: string) {
    const existing = await this.prisma.conversation.findUnique({
      where: { jobId },
      include: {
        job: {
          include: {
            homeowner: { select: { id: true, fullName: true, profilePhoto: true } },
            category: { select: { id: true, name: true } },
          },
        },
      },
    });
    if (existing) return existing;

    const job = await this.prisma.job.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundException(`Job ${jobId} not found`);

    return this.prisma.conversation.create({
      data: { jobId },
      include: {
        job: {
          include: {
            homeowner: { select: { id: true, fullName: true, profilePhoto: true } },
            category: { select: { id: true, name: true } },
          },
        },
      },
    });
  }

  // ─── List all conversations for a user ────────────────────────────────────

  async getConversationsForUser(userId: string) {
    const homeowner = await this.prisma.homeowner.findUnique({
      where: { userId },
    });
    const artisan = await this.prisma.artisan.findUnique({
      where: { userId },
    });

    const conversations = await this.prisma.conversation.findMany({
      where: {
        OR: [
          ...(homeowner ? [{ job: { homeownerId: homeowner.id } }] : []),
          ...(artisan
            ? [
                { job: { booking: { artisanId: artisan.id } } },
                {
                  job: {
                    applications: {
                      some: {
                        artisanId: artisan.id,
                      },
                    },
                  },
                },
              ]
            : []),
          { messages: { some: { senderId: userId } } },
        ],
      },
      include: {
        job: {
          include: {
            homeowner: {
              select: { id: true, fullName: true, profilePhoto: true, userId: true },
            },
            category: { select: { id: true, name: true } },
            booking: {
              include: {
                artisan: {
                  select: { id: true, fullName: true, profilePhoto: true, userId: true },
                },
              },
            },
            applications: {
              include: {
                artisan: {
                  select: { id: true, fullName: true, profilePhoto: true, userId: true },
                },
              },
              orderBy: { createdAt: 'desc' },
            },
          },
        },
        messages: {
          orderBy: { createdAt: 'desc' as const },
          take: 5,
          include: {
            sender: {
              select: {
                id: true,
                role: true,
                artisan: { select: { id: true, fullName: true, profilePhoto: true, userId: true } },
                homeowner: { select: { id: true, fullName: true, profilePhoto: true, userId: true } },
              },
            },
          },
        },
      },
      orderBy: { updatedAt: 'desc' as const },
    });

    // Shape into a format both customer and workers Flutter apps expect
    return conversations.map((conv: any) => {
      const lastMsg = conv.messages?.[0];
      const jobHomeowner = conv.job?.homeowner;

      // 1. Check if job has a booked artisan
      let resolvedArtisan = conv.job?.booking?.artisan;

      // 2. Or check accepted application, then any application
      if (!resolvedArtisan && conv.job?.applications?.length > 0) {
        const acceptedApp = conv.job.applications.find((a: any) => a.status === ApplicationStatus.ACCEPTED);
        resolvedArtisan = acceptedApp?.artisan || conv.job.applications[0]?.artisan;
      }

      // 3. Or check sender of messages in this conversation
      if (!resolvedArtisan && conv.messages?.length > 0) {
        for (const msg of conv.messages) {
          if (msg.sender?.artisan) {
            resolvedArtisan = msg.sender.artisan;
            break;
          }
        }
      }

      // Calculate unread count for current user
      const unreadCount = conv.messages?.filter(
        (m: any) => !m.seen && m.senderId !== userId,
      ).length ?? 0;

      return {
        id: conv.id,
        jobId: conv.jobId,
        updatedAt: conv.updatedAt,
        lastMessage: lastMsg?.message ?? '',
        unreadCount,
        homeowner: jobHomeowner
          ? {
              id: jobHomeowner.id,
              fullName: jobHomeowner.fullName,
              profilePhoto: jobHomeowner.profilePhoto,
              userId: jobHomeowner.userId,
            }
          : null,
        artisan: resolvedArtisan
          ? {
              id: resolvedArtisan.id,
              fullName: resolvedArtisan.fullName,
              profilePhoto: resolvedArtisan.profilePhoto,
              userId: resolvedArtisan.userId,
            }
          : null,
        job: { title: conv.job?.title, category: conv.job?.category },
      };
    });
  }

  // ─── Get messages ──────────────────────────────────────────────────────────

  async getMessages(
    conversationId: string,
    limit?: number,
    before?: string,
  ) {
    return this.prisma.message.findMany({
      where: {
        conversationId,
        ...(before ? { createdAt: { lt: new Date(before) } } : {}),
      },
      include: {
        sender: { select: { id: true, role: true } },
      },
      orderBy: { createdAt: 'asc' },
      take: limit ? Number(limit) : 50,
    });
  }

  // ─── Send message ─────────────────────────────────────────────────────────

  async sendMessage(
    conversationId: string,
    senderId: string,
    message: string,
    attachment?: string[],
  ) {
    const msg = await this.prisma.message.create({
      data: {
        conversationId,
        senderId,
        message,
        attachment: attachment ?? [],
      },
      include: {
        sender: { select: { id: true, role: true } },
      },
    });

    // Touch conversation updatedAt
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    // Broadcast instant message to WebSocket clients in this conversation room
    this.chatGateway.broadcastNewMessage(conversationId, msg);

    // Notify the other party
    try {
      const conversation = await this.prisma.conversation.findUnique({
        where: { id: conversationId },
        include: {
          job: {
            include: {
              homeowner: { select: { userId: true } },
              booking: { include: { artisan: { select: { userId: true } } } },
              applications: {
                where: { status: { in: ['ACCEPTED', 'PENDING'] } },
                include: { artisan: { select: { userId: true } } },
                take: 1,
              },
            },
          },
        },
      });

      if (conversation && conversation.job) {
        const homeownerUserId = conversation.job.homeowner?.userId;
        const artisanUserId = conversation.job.booking?.artisan?.userId ||
                              conversation.job.applications[0]?.artisan?.userId;
        
        let receiverId: string | null | undefined = null;
        if (senderId === homeownerUserId) receiverId = artisanUserId;
        else if (senderId === artisanUserId) receiverId = homeownerUserId;
        
        if (receiverId && receiverId !== senderId) {
          await this.notificationsService.createNotification(
            receiverId,
            'New Message',
            `You received a new message: "${message.length > 30 ? message.substring(0, 30) + '...' : message}"`,
            'GENERAL',
            { conversationId, jobId: conversation.jobId }
          );
        }
      }
    } catch (error) {
      console.error('Failed to send message notification:', error);
    }

    return msg;
  }

  // ─── Mark seen ────────────────────────────────────────────────────────────

  async markSeen(conversationId: string, userId: string) {
    await this.prisma.message.updateMany({
      where: {
        conversationId,
        senderId: { not: userId },
        seen: false,
      },
      data: { seen: true },
    });
    return { success: true };
  }
}
