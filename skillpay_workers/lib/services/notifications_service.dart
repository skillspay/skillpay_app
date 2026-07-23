import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/notification_model.dart';

class NotificationsService {
  final _api = ApiClient.instance;

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final data = await _api.get('/notifications') as List<dynamic>;
      return data
          .map((json) =>
              NotificationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching notifications: ${e.message}');
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.patch('/notifications/$id/read');
    } on ApiException catch (e) {
      debugPrint('Error marking notification read: ${e.message}');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.patch('/notifications/read-all');
    } on ApiException catch (e) {
      debugPrint('Error marking all read: ${e.message}');
    }
  }
}
