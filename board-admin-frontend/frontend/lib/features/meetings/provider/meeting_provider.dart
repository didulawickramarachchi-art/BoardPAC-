import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/notifications/device_notification_service.dart';
import '../../auth/provider/auth_provider.dart';
import '../../privileges/data/privilege_repository.dart';
import '../../privileges/provider/privilege_provider.dart';
import '../data/meeting_repository.dart';
import '../model/meeting_model.dart';
import '../model/meeting_participant_model.dart';
import '../model/meeting_participant_request.dart';
import '../model/meeting_request.dart';
import '../model/participant_status_request.dart';
import '../model/participant_option_model.dart';

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository(ref.read(dioProvider));
});

final meetingListProvider =
    StateNotifierProvider<MeetingNotifier, AsyncValue<List<MeetingModel>>>((
      ref,
    ) {
      final auth = ref.watch(authProvider);
      return MeetingNotifier(
        ref.read(meetingRepositoryProvider),
        ref.read(privilegeRepositoryProvider),
        role: auth.role,
        userId: auth.userId,
      )..loadMeetings();
    });

class MeetingNotifier extends StateNotifier<AsyncValue<List<MeetingModel>>> {
  final MeetingRepository repository;
  final PrivilegeRepository privilegeRepository;
  final String? role;
  final int? userId;

  MeetingNotifier(
    this.repository,
    this.privilegeRepository, {
    required this.role,
    required this.userId,
  }) : super(const AsyncLoading());

  Future<void> loadMeetings() async {
    try {
      final access = RoleAccess(role ?? 'MEMBER');
      List<MeetingModel> data;
      if (access.isMember) {
        final memberId = userId;
        if (memberId == null) {
          data = <MeetingModel>[];
        } else {
          final memberPrivileges = await privilegeRepository
              .getPrivilegesByUser(memberId);
          data = await repository.getMeetingsForMember(
            userId: memberId,
            privilegedSubcategoryIds: memberPrivileges
                .map((privilege) => privilege.subcategoryId)
                .toSet(),
            privilegedSubcategoryNames: memberPrivileges
                .map(
                  (privilege) => privilege.subcategoryName.trim().toLowerCase(),
                )
                .where((name) => name.isNotEmpty)
                .toSet(),
          );
        }
      } else {
        data = await repository.getMeetings();
      }
      state = AsyncData(data);
      for (final meeting in data) {
        if (meeting.type.trim().toUpperCase() != 'MEETING') continue;
        final meetingDateTime = DateTime.tryParse(meeting.meetingDateTime);
        if (meetingDateTime != null) {
          await DeviceNotificationService.instance.scheduleMeetingReminder(
            meetingId: meeting.id,
            title: meeting.title,
            meetingDateTime: meetingDateTime,
          );
        }
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> createMeeting(MeetingRequest request) async {
    final meeting = await repository.createMeeting(request);
    final meetingDateTime = DateTime.tryParse(meeting.meetingDateTime);
    if (meeting.type.trim().toUpperCase() == 'MEETING' &&
        meetingDateTime != null) {
      await DeviceNotificationService.instance.showMeetingCreated(
        meetingId: meeting.id,
        title: meeting.title,
        meetingDateTime: meetingDateTime,
      );
      await DeviceNotificationService.instance.scheduleMeetingReminder(
        meetingId: meeting.id,
        title: meeting.title,
        meetingDateTime: meetingDateTime,
      );
    }
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

final participantOptionsProvider = FutureProvider.autoDispose
    .family<List<ParticipantOptionModel>, int>((ref, meetingId) {
      return ref
          .read(meetingRepositoryProvider)
          .getParticipantOptions(meetingId);
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
