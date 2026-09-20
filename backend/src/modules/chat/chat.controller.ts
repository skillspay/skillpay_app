import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Chat')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  // Webhook: POST /chat/webhook (accepts external triggers or Supabase DB webhooks)
  @Public()
  @Post('webhook')
  @ApiOperation({ summary: 'Webhook to ingest and broadcast instant messages' })
  async handleWebhook(
    @Body()
    body: {
      conversationId?: string;
      senderId?: string;
      message?: string;
      attachmentUrls?: string[];
      record?: {
        conversation_id?: string;
        sender_id?: string;
        message?: string;
        attachment?: string[];
      };
    },
  ) {
    const conversationId = body.conversationId || body.record?.conversation_id;
    const senderId = body.senderId || body.record?.sender_id;
    const message = body.message || body.record?.message;
    const attachments = body.attachmentUrls || body.record?.attachment;

    if (!conversationId || !senderId || !message) {
      return { success: false, error: 'Missing required fields (conversationId, senderId, message)' };
    }

    const saved = await this.chatService.sendMessage(conversationId, senderId, message, attachments);
    return { success: true, message: saved };
  }

  // Flutter: GET /chat/conversations
  @Get('conversations')
  @ApiOperation({ summary: 'List all conversations for current user' })
  getConversations(@CurrentUser() user: AuthenticatedUser) {
    return this.chatService.getConversationsForUser(user.id);
  }

  // Flutter: POST /chat/conversations/:jobId  (get or create)
  @Post('conversations/:jobId')
  @ApiOperation({ summary: 'Get or create conversation for a job' })
  getOrCreate(@Param('jobId') jobId: string) {
    return this.chatService.getOrCreateConversation(jobId);
  }

  // Flutter: GET /chat/conversations/:conversationId/messages
  @Get('conversations/:conversationId/messages')
  @ApiOperation({ summary: 'Get messages in a conversation' })
  getMessages(
    @Param('conversationId') conversationId: string,
    @Query('limit') limit?: number,
    @Query('before') before?: string,
  ) {
    return this.chatService.getMessages(conversationId, limit, before);
  }

  // Flutter: POST /chat/conversations/:conversationId/messages
  @Post('conversations/:conversationId/messages')
  @ApiOperation({ summary: 'Send a message' })
  sendMessage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('conversationId') conversationId: string,
    @Body() body: { message: string; attachmentUrls?: string[]; senderRole?: string },
  ) {
    return this.chatService.sendMessage(
      conversationId,
      user.id,
      body.message,
      body.attachmentUrls,
      body.senderRole,
    );
  }

  // Flutter: PATCH /chat/conversations/:conversationId/mark-seen
  @Patch('conversations/:conversationId/mark-seen')
  @ApiOperation({ summary: 'Mark all messages in a conversation as seen' })
  markSeen(
    @CurrentUser() user: AuthenticatedUser,
    @Param('conversationId') conversationId: string,
  ) {
    return this.chatService.markSeen(conversationId, user.id);
  }
}
