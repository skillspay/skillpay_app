import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skillpay/models/chat_model.dart';
import 'package:skillpay/models/message_model.dart';
import 'package:skillpay/services/api_client.dart';

/// Handles all chat operations.
///
/// REST (via NestJS API):
///   - Fetch conversation list
///   - Fetch message history
///   - Send messages
///   - Upload attachments
///
/// Realtime (via Supabase channel):
///   - Subscribe to live incoming messages within a conversation
///   - Supabase Realtime is the only direct Supabase usage here
class MessagesService {
  final _api = ApiClient.instance;
  final _supabase = Supabase.instance.client;

  RealtimeChannel? _activeChannel;

  // ─── Conversations ────────────────────────────────────────────────────────

  /// Fetch all conversations for the current homeowner.
  Future<List<ChatModel>> fetchConversations() async {
    try {
      final data =
          await _api.get('/chat/conversations') as List<dynamic>;
      return data
          .map((json) => ChatModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching conversations: ${e.message}');
      return [];
    }
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  /// Fetch message history for a conversation.
  /// [before] is an optional cursor (message createdAt ISO string) for pagination.
  Future<List<MessageModel>> fetchMessages(
    String conversationId, {
    int limit = 30,
    String? before,
  }) async {
    try {
      final query = <String, dynamic>{
        'limit': limit,
        if (before != null) 'before': before,
      };
      final data = await _api.get(
        '/chat/conversations/$conversationId/messages',
        query: query,
      ) as List<dynamic>;
      return data
          .map((json) =>
              MessageModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching messages: ${e.message}');
      return [];
    }
  }

  /// Send a text message to a conversation.
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String message,
    List<String>? attachmentUrls,
  }) async {
    try {
      final data = await _api.post(
        '/chat/conversations/$conversationId/messages',
        body: {
          'message': message,
          if (attachmentUrls != null && attachmentUrls.isNotEmpty)
            'attachmentUrls': attachmentUrls,
        },
      ) as Map<String, dynamic>;
      return MessageModel.fromMap(data);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Upload a chat attachment and return its public URL.
  Future<String?> uploadAttachment(File file) async {
    try {
      final result = await _api.uploadFile(
        '/storage/chat-attachment',
        file: file,
        fieldName: 'file',
      ) as Map<String, dynamic>;
      return result['url']?.toString();
    } on ApiException catch (e) {
      debugPrint('Attachment upload failed: ${e.message}');
      return null;
    }
  }

  // ─── Realtime ─────────────────────────────────────────────────────────────

  /// Subscribe to live messages for a conversation.
  ///
  /// Supabase Realtime listens to INSERT events on the `messages` table
  /// filtered by `conversation_id`. New messages are delivered via [onMessage].
  ///
  /// Call [unsubscribe] when leaving the chat screen.
  void subscribeToMessages({
    required String conversationId,
    required void Function(MessageModel message) onMessage,
  }) {
    // Unsubscribe from any previous channel first
    unsubscribe();

    _activeChannel = _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final newRecord =
                  payload.newRecord as Map<String, dynamic>;
              onMessage(MessageModel.fromMap(newRecord));
            } catch (e) {
              debugPrint('Realtime parse error: $e');
            }
          },
        )
        .subscribe();
  }

  /// Unsubscribe from the active Realtime channel.
  void unsubscribe() {
    if (_activeChannel != null) {
      _supabase.removeChannel(_activeChannel!);
      _activeChannel = null;
    }
  }

  // ─── Mark as seen ─────────────────────────────────────────────────────────

  /// Mark all messages in a conversation as seen.
  Future<void> markConversationAsSeen(String conversationId) async {
    try {
      await _api.patch(
          '/chat/conversations/$conversationId/mark-seen');
    } on ApiException catch (e) {
      debugPrint('Error marking messages as seen: ${e.message}');
    }
  }
}
