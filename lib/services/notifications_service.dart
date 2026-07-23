import 'package:flutter/foundation.dart';
import 'package:skillpay/models/notification_model.dart';
import 'package:skillpay/services/api_client.dart';

class NotificationsService {
  final _api = ApiClient.instance;

  /// Fetch all notifications for the current user, newest first.
  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final data =
          await _api.get('/notifications') as List<dynamic>;
      return data
          .map((json) =>
              NotificationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching notifications: ${e.message}');
      return [];
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.patch('/notifications/$notificationId/read');
    } on ApiException catch (e) {
      debugPrint('Error marking notification as read: ${e.message}');
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    try {
      await _api.patch('/notifications/read-all');
    } on ApiException catch (e) {
      debugPrint('Error marking all notifications as read: ${e.message}');
    }
  }
}
