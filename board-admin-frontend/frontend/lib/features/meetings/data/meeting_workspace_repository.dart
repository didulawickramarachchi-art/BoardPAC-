import 'package:dio/dio.dart';
import '../model/meeting_minutes_model.dart';
import '../model/private_meeting_note_model.dart';

class MeetingWorkspaceRepository {
  final Dio dio;
  MeetingWorkspaceRepository(this.dio);

  Future<List<PrivateMeetingNoteModel>> getNotes(int meetingId) async {
    final response = await dio.get('/meeting-workspace/$meetingId/notes');
    return (response.data as List)
        .map((item) => PrivateMeetingNoteModel.fromJson(item))
        .toList();
  }

  Future<void> addNote(int meetingId, String text) =>
      dio.post('/meeting-workspace/$meetingId/notes', data: {'noteText': text});

  Future<void> updateNote(int noteId, String text) =>
      dio.put('/meeting-workspace/notes/$noteId', data: {'noteText': text});

  Future<void> deleteNote(int noteId) =>
      dio.delete('/meeting-workspace/notes/$noteId');

  Future<List<MeetingMinutesModel>> getMinutes(int meetingId) async {
    final response = await dio.get('/meeting-workspace/$meetingId/minutes');
    return (response.data as List)
        .map((item) => MeetingMinutesModel.fromJson(item))
        .toList();
  }

  Future<void> createMinutes(int meetingId, String content) => dio.post(
    '/meeting-workspace/$meetingId/minutes',
    data: {'content': content},
  );

  Future<void> transitionMinutes(
    int minutesId,
    String action, {
    String? comment,
  }) => dio.put(
    '/meeting-workspace/minutes/$minutesId/$action',
    data: {'reviewComment': comment},
  );
}
