import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

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
    // Find conversations tied to jobs the user owns (as homeowner)
    // or has an accepted/confirmed booking (as artisan)
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
            ? [{ job: { applications: { some: { artisanId: artisan.id, status: { in: ['ACCEPTED', 'PENDING'] } } } } }]
            : []),
        ],
      },
      include: {
        job: {
          include: {
            homeowner: { select: { id: true, fullName: true, profilePhoto: true } },
            category: { select: { id: true, name: true } },
          },
        },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: { sender: { select: { id: true, role: true } } },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    // Shape into a format the Flutter app expects
    return conversations.map((conv) => {
      const lastMsg = conv.messages[0];
      const otherParty = artisan
        ? conv.job.homeowner
        : null;

      return {
        id: conv.id,
        jobId: conv.jobId,
        updatedAt: conv.updatedAt,
        lastMessage: lastMsg?.message ?? '',
        unreadCount: 0, // TODO: compute with seen flag
        homeowner: otherParty,
        artisan: artisan ? { id: artisan.id } : null,
        job: { title: conv.job.title, category: conv.job.category },
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
