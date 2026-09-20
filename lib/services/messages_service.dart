import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:skillpay/models/chat_model.dart';
import 'package:skillpay/models/message_model.dart';
import 'package:skillpay/services/api_client.dart';

/// Handles all chat operations via REST API and direct WebSockets.
/// Independent of Supabase Realtime.
class MessagesService {
  final _api = ApiClient.instance;

  io.Socket? _socket;
  String? _currentConversationId;

  String get _socketUrl {
    final url = dotenv.env['API_URL'] ?? 'https://backend.skillspays.com/api/v1';
    final uri = Uri.parse(url);
    final baseUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    return '$baseUrl/chat';
  }

  void _initSocket() {
    if (_socket != null) return;
    try {
      _socket = io.io(
        _socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.onConnect((_) {
        debugPrint('Chat WebSocket connected to $_socketUrl');
        if (_currentConversationId != null) {
          _socket?.emit('join_conversation', _currentConversationId);
        }
      });

      _socket?.onDisconnect((_) {
        debugPrint('Chat WebSocket disconnected');
      });

      _socket?.onError((err) {
        debugPrint('Chat WebSocket error: $err');
      });
    } catch (e) {
      debugPrint('Error initializing chat socket: $e');
    }
  }

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
          'senderRole': 'HOMEOWNER',
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

  // ─── Direct WebSocket Realtime ───────────────────────────────────────────

  /// Subscribe to live messages for a conversation via WebSocket.
  void subscribeToMessages({
    required String conversationId,
    required String currentUserId,
    required void Function(MessageModel message) onMessage,
    required void Function(bool isTyping) onTyping,
  }) {
    unsubscribe();
    _currentConversationId = conversationId;
    _initSocket();

    if (_socket?.connected == true) {
      _socket?.emit('join_conversation', conversationId);
    }

    _socket?.on('new_message', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        onMessage(MessageModel.fromMap(map));
      } catch (e) {
        debugPrint('WebSocket new_message parse error: $e');
      }
    });

    _socket?.on('typing', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        if (map['userId'] != currentUserId) {
          onTyping(map['isTyping'] == true);
        }
      } catch (_) {}
    });
  }

  void updateTypingStatus(String currentUserId, bool isTyping) {
    if (_currentConversationId != null && _socket?.connected == true) {
      _socket?.emit('typing', {
        'conversationId': _currentConversationId,
        'userId': currentUserId,
        'isTyping': isTyping,
      });
    }
  }

  /// Leave conversation room and clear listeners.
  void unsubscribe() {
    if (_currentConversationId != null) {
      _socket?.emit('leave_conversation', _currentConversationId);
      _currentConversationId = null;
    }
    _socket?.off('new_message');
    _socket?.off('typing');
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
