import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Chat')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

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
    @Body() body: { message: string; attachmentUrls?: string[] },
  ) {
    return this.chatService.sendMessage(
      conversationId,
      user.id,
      body.message,
      body.attachmentUrls,
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
