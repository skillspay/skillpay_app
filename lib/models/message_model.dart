/// Matches the NestJS messages response shape.
///
/// DB table: messages
/// NestJS endpoint: GET /chat/conversations/:id/messages
/// Realtime: Supabase channel `messages:conversation_id=eq.<id>`
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderRole;
  final String message;
  final List<String> attachmentUrls;
  final bool seen;
  final DateTime createdAt;
  bool isSending;
  bool hasError;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderRole,
    required this.message,
    required this.attachmentUrls,
    required this.seen,
    required this.createdAt,
    this.isSending = false,
    this.hasError = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    final rawAttachments = map['attachment'] ?? map['attachmentUrls'] ?? [];
    List<String> attachments = [];
    if (rawAttachments is List) {
      attachments = List<String>.from(rawAttachments.whereType<String>());
    } else if (rawAttachments is String && rawAttachments.isNotEmpty) {
      attachments = [rawAttachments];
    }

    return MessageModel(
      id: map['id']?.toString() ?? '',
      conversationId: map['conversationId']?.toString() ??
          map['conversation_id']?.toString() ??
          '',
      senderId: map['senderId']?.toString() ??
          map['sender_id']?.toString() ??
          '',
      senderRole: map['senderRole']?.toString() ??
          map['sender_role']?.toString() ??
          (map['sender'] is Map ? (map['sender'] as Map)['role']?.toString() : null),
      message: map['message']?.toString() ?? '',
      attachmentUrls: attachments,
      seen: (map['seen'] as bool?) ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ??
              DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'message': message,
        if (attachmentUrls.isNotEmpty) 'attachmentUrls': attachmentUrls,
      };
}
