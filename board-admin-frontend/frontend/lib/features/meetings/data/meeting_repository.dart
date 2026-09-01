import 'package:dio/dio.dart';
import '../model/meeting_model.dart';
import '../model/meeting_participant_model.dart';
import '../model/meeting_participant_request.dart';
import '../model/meeting_request.dart';
import '../model/participant_status_request.dart';
import '../model/participant_option_model.dart';

class MeetingRepository {
  final Dio dio;

  MeetingRepository(this.dio);

  Future<List<MeetingModel>> getMeetings() async {
    final response = await dio.get('/meetings');
    return (response.data as List)
        .map((e) => MeetingModel.fromJson(e))
        .toList();
  }

  Future<MeetingModel> createMeeting(MeetingRequest request) async {
    final response = await dio.post('/meetings', data: request.toJson());
    return MeetingModel.fromJson(response.data);
  }

  Future<void> openMeeting(int meetingId) async {
    await dio.put('/meetings/$meetingId/open');
  }

  Future<void> closeMeeting(int meetingId) async {
    await dio.put('/meetings/$meetingId/close');
  }

  Future<void> deleteMeeting(int meetingId) async {
    await dio.delete('/meetings/$meetingId');
  }

  Future<List<MeetingParticipantModel>> getParticipants(int meetingId) async {
    final response = await dio.get('/meetings/$meetingId/participants');
    return (response.data as List)
        .map((e) => MeetingParticipantModel.fromJson(e))
        .toList();
  }

  Future<List<MeetingModel>> getMeetingsForMember({
    required int userId,
    required Set<int> privilegedSubcategoryIds,
    required Set<String> privilegedSubcategoryNames,
  }) async {
    if (privilegedSubcategoryIds.isEmpty) return <MeetingModel>[];

    final responses = await Future.wait(
      privilegedSubcategoryIds.map(
        (subcategoryId) => dio.get('/meetings/subcategory/$subcategoryId'),
      ),
    );

    final meetingsById = <int, MeetingModel>{};
    for (final response in responses) {
      for (final item in response.data as List) {
        final meeting = MeetingModel.fromJson(item);
        meetingsById[meeting.id] = meeting;
      }
    }

    final meetings = meetingsById.values.toList()
      ..sort((a, b) => a.meetingDateTime.compareTo(b.meetingDateTime));
    return meetings;
  }

  Future<List<ParticipantOptionModel>> getParticipantOptions(
    int meetingId,
  ) async {
    final response = await dio.get('/meetings/$meetingId/participant-options');
    return (response.data as List)
        .map((item) => ParticipantOptionModel.fromJson(item))
        .toList();
  }

  Future<void> addParticipant(MeetingParticipantRequest request) async {
    await dio.post('/meetings/participants', data: request.toJson());
  }

  Future<void> updateParticipantStatus(ParticipantStatusRequest request) async {
    await dio.put('/meetings/participants/status', data: request.toJson());
  }

  Future<void> rsvp(int meetingId, String status, String? reason) async {
    await dio.put(
      '/meetings/$meetingId/rsvp',
      data: {'participantStatus': status, 'statusReason': reason},
    );
  }
}
