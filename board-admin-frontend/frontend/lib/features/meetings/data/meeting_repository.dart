import 'package:dio/dio.dart';
import '../model/meeting_model.dart';
import '../model/meeting_participant_model.dart';
import '../model/meeting_participant_request.dart';
import '../model/meeting_request.dart';
import '../model/participant_status_request.dart';

class MeetingRepository {
  final Dio dio;

  MeetingRepository(this.dio);

  Future<List<MeetingModel>> getMeetings() async {
    final response = await dio.get('/meetings');
    return (response.data as List)
        .map((e) => MeetingModel.fromJson(e))
        .toList();
  }

  Future<void> createMeeting(MeetingRequest request) async {
    await dio.post('/meetings', data: request.toJson());
  }

  Future<void> openMeeting(int meetingId) async {
    await dio.put('/meetings/$meetingId/open');
  }

  Future<void> closeMeeting(int meetingId) async {
    await dio.put('/meetings/$meetingId/close');
  }

  Future<List<MeetingParticipantModel>> getParticipants(int meetingId) async {
    final response = await dio.get('/meetings/$meetingId/participants');
    return (response.data as List)
        .map((e) => MeetingParticipantModel.fromJson(e))
        .toList();
  }

  Future<void> addParticipant(MeetingParticipantRequest request) async {
    await dio.post('/meetings/participants', data: request.toJson());
  }

  Future<void> updateParticipantStatus(ParticipantStatusRequest request) async {
    await dio.put('/meetings/participants/status', data: request.toJson());
  }
}
