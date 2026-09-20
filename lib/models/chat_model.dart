/// Matches the NestJS conversations response shape.
///
/// DB table: conversations (joined with latest message + artisan profile)
/// NestJS endpoint: GET /chat/conversations
class ChatModel {
  final String id; // conversations.id
  final String jobId;
  final String jobTitle;
  final String? categoryName;
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
    this.jobTitle = '',
    this.categoryName,
    required this.artisanId,
    required this.artisanName,
    this.artisanAvatarUrl,
    required this.lastMessage,
    required this.timeText,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    final artisan = (map['artisan'] is Map)
        ? Map<String, dynamic>.from(map['artisan'] as Map)
        : <String, dynamic>{};
    final job = (map['job'] is Map)
        ? Map<String, dynamic>.from(map['job'] as Map)
        : <String, dynamic>{};
    final category = (job['category'] is Map)
        ? Map<String, dynamic>.from(job['category'] as Map)
        : null;

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

    String parsedName = artisan['fullName']?.toString() ??
        artisan['full_name']?.toString() ??
        map['artisanName']?.toString() ??
        '';

    final String jobTitle = job['title']?.toString() ?? '';

    if (parsedName.isEmpty || parsedName.trim().toLowerCase() == 'artisan') {
      if (jobTitle.isNotEmpty) {
        parsedName = jobTitle;
      } else {
        parsedName = 'Artisan';
      }
    }

    final avatar = artisan['profilePhoto']?.toString() ??
        artisan['profile_photo']?.toString() ??
        map['artisanAvatarUrl']?.toString();

    return ChatModel(
      id: map['id']?.toString() ?? '',
      jobId: map['jobId']?.toString() ?? map['job_id']?.toString() ?? '',
      jobTitle: jobTitle,
      categoryName: category?['name']?.toString(),
      artisanId: map['artisanId']?.toString() ??
          map['artisan_id']?.toString() ??
          artisan['id']?.toString() ??
          '',
      artisanName: parsedName,
      artisanAvatarUrl: (avatar != null && avatar.isNotEmpty) ? avatar : null,
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
