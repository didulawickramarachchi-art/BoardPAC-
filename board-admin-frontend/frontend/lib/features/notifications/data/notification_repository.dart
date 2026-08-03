import 'package:dio/dio.dart';

import '../model/notification_model.dart';
import '../model/notification_request.dart';

class NotificationRepository {
  final Dio dio;

  const NotificationRepository(this.dio);

  Future<List<NotificationModel>> getForUser(int userId) async {
    final response = await dio.get('/notifications/user/$userId');
    final data = response.data;
    final items = data is List
        ? data
        : data is Map<String, dynamic>
        ? data['notifications'] ?? data['items'] ?? data['content'] ?? const []
        : const [];

    return (items as List)
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  Future<void> createAnnouncement(NotificationRequest request) async {
    await dio.post('/notifications/announcement', data: request.toJson());
  }

  Future<void> markAllRead(int userId) async {
    await dio.put('/notifications/user/$userId/read');
  }

  Future<void> clearForUser(int userId) async {
    await dio.delete('/notifications/user/$userId');
  }

  Future<NotificationModel> reply(int notificationId, String message) async {
    final response = await dio.post(
      '/notifications/$notificationId/reply',
      data: {'message': message},
    );
    return NotificationModel.fromJson(response.data);
  }

  Future<NotificationModel> react(
    int notificationId,
    String reactionType,
  ) async {
    final response = await dio.post(
      '/notifications/$notificationId/reaction',
      data: {'reactionType': reactionType},
    );
    return NotificationModel.fromJson(response.data);
  }
}
