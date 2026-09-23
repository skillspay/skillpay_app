import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_client.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Chat service for the Workers app.
///
/// REST  → NestJS API (conversation list, history, send)
/// Realtime → Direct WebSocket Gateway (/chat)
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
        debugPrint('Workers Chat WebSocket connected to $_socketUrl');
        if (_currentConversationId != null) {
          _socket?.emit('join_conversation', _currentConversationId);
        }
      });

      _socket?.onDisconnect((_) {
        debugPrint('Workers Chat WebSocket disconnected');
      });

      _socket?.onError((err) {
        debugPrint('Workers Chat WebSocket error: $err');
      });
    } catch (e) {
      debugPrint('Error initializing workers chat socket: $e');
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

  static final Map<String, List<MessageModel>> _cachedMessages = {};

  /// Get locally cached messages if available for instantaneous rendering
  List<MessageModel>? getCachedMessages(String conversationId) {
    final cached = _cachedMessages[conversationId];
    return cached != null ? List.from(cached) : null;
  }

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
          ...?before != null ? {'before': before} : null,
        },
      ) as List<dynamic>;
      final messages = data
          .map((json) => MessageModel.fromMap(json as Map<String, dynamic>))
          .toList();
      if (before == null) {
        _cachedMessages[conversationId] = messages;
      }
      return messages;
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
          'senderRole': 'ARTISAN',
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

  // ─── Direct WebSocket Realtime ───────────────────────────────────────────

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
        debugPrint('Workers WebSocket new_message parse error: $e');
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

  void unsubscribe() {
    if (_currentConversationId != null) {
      _socket?.emit('leave_conversation', _currentConversationId);
      _currentConversationId = null;
    }
    _socket?.off('new_message');
    _socket?.off('typing');
  }

  Future<void> markConversationAsSeen(String conversationId) async {
    try {
      await _api.patch('/chat/conversations/$conversationId/mark-seen');
    } on ApiException catch (e) {
      debugPrint('Error marking seen: ${e.message}');
    }
  }
}
