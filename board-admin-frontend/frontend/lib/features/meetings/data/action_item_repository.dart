import 'package:dio/dio.dart';
import '../model/action_item_model.dart';

class ActionItemRepository {
  final Dio dio;
  ActionItemRepository(this.dio);
  Future<List<ActionItemModel>> list(int meetingId) async =>
      ((await dio.get('/meetings/$meetingId/action-items')).data as List)
          .map((e) => ActionItemModel.fromJson(e))
          .toList();
  Future<void> create(
    int meetingId, {
    required String title,
    String? description,
    required int assigneeUserId,
    DateTime? dueDate,
  }) async => dio.post(
    '/meetings/$meetingId/action-items',
    data: {
      'title': title,
      'description': description,
      'assigneeUserId': assigneeUserId,
      'dueDate': dueDate?.toIso8601String().split('T').first,
    },
  );
  Future<void> updateStatus(
    int meetingId,
    int id,
    String status,
    String? note,
  ) async => dio.put(
    '/meetings/$meetingId/action-items/$id/status',
    data: {'status': status, 'completionNote': note},
  );
  Future<void> delete(int meetingId, int id) async =>
      dio.delete('/meetings/$meetingId/action-items/$id');
}
