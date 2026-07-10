import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/meeting_repository.dart';
import '../model/meeting_model.dart';
import '../model/meeting_participant_model.dart';
import '../model/meeting_participant_request.dart';
import '../model/meeting_request.dart';
import '../model/participant_status_request.dart';

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository(ref.read(dioProvider));
});

final meetingListProvider =
    StateNotifierProvider<MeetingNotifier, AsyncValue<List<MeetingModel>>>((
      ref,
    ) {
      return MeetingNotifier(ref.read(meetingRepositoryProvider))
        ..loadMeetings();
    });

class MeetingNotifier extends StateNotifier<AsyncValue<List<MeetingModel>>> {
  final MeetingRepository repository;

  MeetingNotifier(this.repository) : super(const AsyncLoading());

  Future<void> loadMeetings() async {
    try {
      final data = await repository.getMeetings();
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> createMeeting(MeetingRequest request) async {
    await repository.createMeeting(request);
    await loadMeetings();
  }

  Future<void> openMeeting(int meetingId) async {
    await repository.openMeeting(meetingId);
    await loadMeetings();
  }

  Future<void> closeMeeting(int meetingId) async {
    await repository.closeMeeting(meetingId);
    await loadMeetings();
  }

  Future<void> deleteMeeting(int meetingId) async {
    await repository.deleteMeeting(meetingId);
    final current = state.valueOrNull ?? <MeetingModel>[];
    state = AsyncData(
      current.where((meeting) => meeting.id != meetingId).toList(),
    );
  }
}

final participantListProvider =
    StateNotifierProvider.family<
      ParticipantNotifier,
      AsyncValue<List<MeetingParticipantModel>>,
      int
    >((ref, meetingId) {
      return ParticipantNotifier(ref.read(meetingRepositoryProvider), meetingId)
        ..load();
    });

class ParticipantNotifier
    extends StateNotifier<AsyncValue<List<MeetingParticipantModel>>> {
  final MeetingRepository repository;
  final int meetingId;

  ParticipantNotifier(this.repository, this.meetingId)
    : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getParticipants(meetingId);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addParticipant(MeetingParticipantRequest request) async {
    await repository.addParticipant(request);
    await load();
  }

  Future<void> updateStatus(ParticipantStatusRequest request) async {
    await repository.updateParticipantStatus(request);
    await load();
  }
}
