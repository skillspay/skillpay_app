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

  // ─── User Identity ────────────────────────────────────────────────────────
  
  static String? _cachedPrismaUserId;

  /// Fetches the user's Prisma ID from the backend to determine if a message is from the current user.
  Future<String?> getMyPrismaUserId() async {
    if (_cachedPrismaUserId != null) return _cachedPrismaUserId;
    try {
      final data = await _api.get('/auth/me');
      _cachedPrismaUserId = data['id']?.toString();
      return _cachedPrismaUserId;
    } catch (e) {
      debugPrint('Error fetching my Prisma user ID: $e');
      return null;
    }
  }

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

  /// Get or create a conversation for a specific job.
  Future<ChatModel?> getOrCreateConversation(String jobId) async {
    try {
      final data = await _api.post('/chat/conversations/$jobId') as Map<String, dynamic>;
      return ChatModel.fromMap(data);
    } on ApiException catch (e) {
      debugPrint('Error getting/creating conversation: ${e.message}');
      return null;
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
    required String currentUserId,
    required void Function(MessageModel message) onMessage,
    required void Function(bool isTyping) onTyping,
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
              final newRecord = payload.newRecord;
              onMessage(MessageModel.fromMap(newRecord));
            } catch (e) {
              debugPrint('Realtime parse error: $e');
            }
          },
        )
        .onPresenceSync((payload) {
          final presenceState = _activeChannel?.presenceState();
          if (presenceState != null) {
            bool typing = false;
            for (final state in presenceState) {
              for (final presence in state.presences) {
                final payload = presence.payload;
                if (payload['user_id'] != currentUserId && payload['typing'] == true) {
                  typing = true;
                }
              }
            }
            onTyping(typing);
          }
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _activeChannel?.track({'user_id': currentUserId, 'typing': false});
          }
        });
  }

  Future<void> updateTypingStatus(String currentUserId, bool isTyping) async {
    if (_activeChannel != null) {
      try {
        await _activeChannel!.track({'user_id': currentUserId, 'typing': isTyping});
      } catch (e) {
        debugPrint('Error updating typing status: $e');
      }
    }
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
