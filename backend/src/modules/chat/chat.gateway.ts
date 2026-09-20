import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, Inject, forwardRef } from '@nestjs/common';
import { ChatService } from './chat.service';

@WebSocketGateway({ cors: { origin: '*' }, namespace: 'chat' })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  constructor(
    @Inject(forwardRef(() => ChatService))
    private readonly chatService: ChatService,
  ) {}

  handleConnection(client: Socket) {
    this.logger.log(`WebSocket client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`WebSocket client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join_conversation')
  handleJoin(@ConnectedSocket() client: Socket, @MessageBody() conversationId: string) {
    client.join(conversationId);
    this.logger.log(`Client ${client.id} joined conversation ${conversationId}`);
  }

  @SubscribeMessage('leave_conversation')
  handleLeave(@ConnectedSocket() client: Socket, @MessageBody() conversationId: string) {
    client.leave(conversationId);
    this.logger.log(`Client ${client.id} left conversation ${conversationId}`);
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { conversationId: string; userId: string; isTyping: boolean },
  ) {
    client.to(payload.conversationId).emit('typing', payload);
  }

  @SubscribeMessage('send_message')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { conversationId: string; senderId: string; message: string; attachment?: string[] },
  ) {
    return this.chatService.sendMessage(
      payload.conversationId,
      payload.senderId,
      payload.message,
      payload.attachment,
    );
  }

  @SubscribeMessage('mark_seen')
  async handleMarkSeen(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { conversationId: string; userId: string },
  ) {
    await this.chatService.markSeen(payload.conversationId, payload.userId);
    this.server.to(payload.conversationId).emit('messages_seen', { userId: payload.userId });
  }

  broadcastNewMessage(conversationId: string, message: any) {
    if (this.server) {
      this.server.to(conversationId).emit('new_message', message);
      this.logger.log(`Broadcasted new_message ${message.id} to room ${conversationId}`);
    }
  }
}

