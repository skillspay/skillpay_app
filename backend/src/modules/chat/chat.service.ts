import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  async getOrCreateConversation(jobId: string) {
    const existing = await this.prisma.conversation.findUnique({ where: { jobId } });
    if (existing) return existing;

    const job = await this.prisma.job.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundException(`Job ${jobId} not found`);

    return this.prisma.conversation.create({ data: { jobId } });
  }

  async getMessages(conversationId: string) {
    return this.prisma.message.findMany({
      where: { conversationId },
      include: { sender: { select: { id: true, email: true, role: true } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  async sendMessage(conversationId: string, senderId: string, message: string, attachment?: string[]) {
    return this.prisma.message.create({
      data: {
        conversationId,
        senderId,
        message,
        attachment: attachment || [],
      },
      include: { sender: { select: { id: true, email: true, role: true } } },
    });
  }

  async markSeen(conversationId: string, userId: string) {
    await this.prisma.message.updateMany({
      where: { conversationId, senderId: { not: userId }, seen: false },
      data: { seen: true },
    });
  }
}
