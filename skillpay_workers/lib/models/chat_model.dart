class ChatModel {
  final String id;
  final String jobId;
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
    required this.homeownerId,
    required this.homeownerName,
    this.homeownerAvatarUrl,
    required this.lastMessage,
    required this.timeText,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    final homeowner = map['homeowner'] as Map<String, dynamic>? ?? {};
    final updatedAt = map['updatedAt'] != null
        ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    final diff = DateTime.now().difference(updatedAt);
    String timeText = 'Just now';
    if (diff.inDays > 0) timeText = '${diff.inDays}d';
    else if (diff.inHours > 0) timeText = '${diff.inHours}h';
    else if (diff.inMinutes > 0) timeText = '${diff.inMinutes}m';

    return ChatModel(
      id: map['id']?.toString() ?? '',
      jobId: map['jobId']?.toString() ?? map['job_id']?.toString() ?? '',
      homeownerId: homeowner['id']?.toString() ?? map['homeownerId']?.toString() ?? '',
      homeownerName: homeowner['fullName']?.toString() ?? homeowner['full_name']?.toString() ?? 'Homeowner',
      homeownerAvatarUrl: homeowner['profilePhoto']?.toString(),
      lastMessage: map['lastMessage']?.toString() ?? map['last_message']?.toString() ?? '',
      timeText: map['timeText']?.toString() ?? timeText,
      unreadCount: (map['unreadCount'] as int?) ?? (map['unread_count'] as int?) ?? 0,
      updatedAt: updatedAt,
    );
  }
}
