import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Chat service for the Workers app.
///
/// REST  → NestJS API (conversation list, history, send)
/// Realtime → Supabase channel (live incoming messages)
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

  Future<List<ChatModel>> fetchConversations() async {
    try {
      final data = await _api.get('/chat/conversations') as List<dynamic>;
      return data
          .map((json) => ChatModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching conversations: ${e.message}');
      return [];
    }
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  Future<List<MessageModel>> fetchMessages(
    String conversationId, {
    int limit = 30,
    String? before,
  }) async {
    try {
      final data = await _api.get(
        '/chat/conversations/$conversationId/messages',
        query: {
          'limit': limit,
          if (before != null) 'before': before,
        },
      ) as List<dynamic>;
      return data
          .map((json) => MessageModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching messages: ${e.message}');
      return [];
    }
  }

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

  void subscribeToMessages({
    required String conversationId,
    required String currentUserId,
    required void Function(MessageModel message) onMessage,
    required void Function(bool isTyping) onTyping,
  }) {
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
              final newRecord = payload.newRecord as Map<String, dynamic>;
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
            for (final key in presenceState.keys) {
              final presences = presenceState[key]!;
              for (final presence in presences) {
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

  void unsubscribe() {
    if (_activeChannel != null) {
      _supabase.removeChannel(_activeChannel!);
      _activeChannel = null;
    }
  }

  Future<void> markConversationAsSeen(String conversationId) async {
    try {
      await _api.patch('/chat/conversations/$conversationId/mark-seen');
    } on ApiException catch (e) {
      debugPrint('Error marking seen: ${e.message}');
    }
  }
}
