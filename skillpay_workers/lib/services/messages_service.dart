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
    required void Function(MessageModel message) onMessage,
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
        .subscribe();
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
