/// Matches the NestJS conversations response shape.
///
/// DB table: conversations (joined with latest message + artisan profile)
/// NestJS endpoint: GET /chat/conversations
class ChatModel {
  final String id; // conversations.id
  final String jobId;
  final String artisanId;
  final String artisanName;
  final String? artisanAvatarUrl;
  final String lastMessage;
  final String timeText;
  final int unreadCount;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.jobId,
    required this.artisanId,
    required this.artisanName,
    this.artisanAvatarUrl,
    required this.lastMessage,
    required this.timeText,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    final artisan = map['artisan'] as Map<String, dynamic>? ?? {};
    final updatedAt = map['updatedAt'] != null
        ? DateTime.tryParse(map['updatedAt'].toString()) ??
            DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
            DateTime.now()
        : DateTime.now();

    final diff = DateTime.now().difference(updatedAt);
    String timeText = 'Just now';
    if (diff.inDays > 0) {
      timeText = '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      timeText = '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      timeText = '${diff.inMinutes}m';
    }

    return ChatModel(
      id: map['id']?.toString() ?? '',
      jobId: map['jobId']?.toString() ?? map['job_id']?.toString() ?? '',
      artisanId: map['artisanId']?.toString() ??
          map['artisan_id']?.toString() ??
          artisan['id']?.toString() ??
          '',
      artisanName: artisan['fullName']?.toString() ??
          artisan['full_name']?.toString() ??
          map['artisanName']?.toString() ??
          'Artisan',
      artisanAvatarUrl: artisan['profilePhoto']?.toString() ??
          artisan['profile_photo']?.toString() ??
          map['artisanAvatarUrl']?.toString(),
      lastMessage: map['lastMessage']?.toString() ??
          map['last_message']?.toString() ??
          '',
      timeText: map['timeText']?.toString() ?? timeText,
      unreadCount: (map['unreadCount'] as int?) ??
          (map['unread_count'] as int?) ??
          0,
      updatedAt: updatedAt,
    );
  }
}
