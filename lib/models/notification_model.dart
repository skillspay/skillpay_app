import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Matches the NestJS notifications response shape.
///
/// DB table: notifications
/// NestJS endpoint: GET /notifications
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // job | proposal | payment | booking | general
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Notification',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      isRead: (map['read'] as bool?) ?? (map['is_read'] as bool?) ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ??
              DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'payment':
        return Icons.attach_money_rounded;
      case 'job':
        return Icons.work_outline_rounded;
      case 'proposal':
      case 'application':
        return Icons.description_outlined;
      case 'booking':
        return Icons.calendar_today_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      return 'Today ${DateFormat('hh:mm a').format(createdAt)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday ${DateFormat('hh:mm a').format(createdAt)}';
    } else {
      return DateFormat('MMM d, hh:mm a').format(createdAt);
    }
  }
}
