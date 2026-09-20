class ChatModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String? categoryName;
  final String homeownerId;
  final String homeownerName;
  final String? homeownerAvatarUrl;
  final String lastMessage;
  final String timeText;
  final int unreadCount;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.jobId,
    this.jobTitle = '',
    this.categoryName,
    required this.homeownerId,
    required this.homeownerName,
    this.homeownerAvatarUrl,
    required this.lastMessage,
    required this.timeText,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    final homeowner = (map['homeowner'] is Map)
        ? Map<String, dynamic>.from(map['homeowner'] as Map)
        : <String, dynamic>{};
    final job = (map['job'] is Map)
        ? Map<String, dynamic>.from(map['job'] as Map)
        : <String, dynamic>{};
    final category = (job['category'] is Map)
        ? Map<String, dynamic>.from(job['category'] as Map)
        : null;

    final updatedAt = map['updatedAt'] != null
        ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
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

    String parsedName = homeowner['fullName']?.toString() ??
        homeowner['full_name']?.toString() ??
        map['homeownerName']?.toString() ??
        '';

    final String jobTitle = job['title']?.toString() ?? '';

    if (parsedName.isEmpty || parsedName.trim().toLowerCase() == 'homeowner') {
      if (jobTitle.isNotEmpty) {
        parsedName = jobTitle;
      } else {
        parsedName = 'Homeowner';
      }
    }

    final avatar = homeowner['profilePhoto']?.toString() ??
        homeowner['profile_photo']?.toString() ??
        map['homeownerAvatarUrl']?.toString();

    return ChatModel(
      id: map['id']?.toString() ?? '',
      jobId: map['jobId']?.toString() ?? map['job_id']?.toString() ?? '',
      jobTitle: jobTitle,
      categoryName: category?['name']?.toString(),
      homeownerId: homeowner['id']?.toString() ?? map['homeownerId']?.toString() ?? '',
      homeownerName: parsedName,
      homeownerAvatarUrl: (avatar != null && avatar.isNotEmpty) ? avatar : null,
      lastMessage: map['lastMessage']?.toString() ?? map['last_message']?.toString() ?? '',
      timeText: map['timeText']?.toString() ?? timeText,
      unreadCount: (map['unreadCount'] as int?) ?? (map['unread_count'] as int?) ?? 0,
      updatedAt: updatedAt,
    );
  }
}
