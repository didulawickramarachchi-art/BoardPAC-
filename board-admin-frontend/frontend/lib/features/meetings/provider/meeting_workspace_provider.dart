import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/meeting_workspace_repository.dart';
import '../model/meeting_minutes_model.dart';
import '../model/private_meeting_note_model.dart';

final meetingWorkspaceRepositoryProvider = Provider<MeetingWorkspaceRepository>(
  (ref) => MeetingWorkspaceRepository(ref.read(dioProvider)),
);

final privateMeetingNotesProvider = FutureProvider.autoDispose
    .family<List<PrivateMeetingNoteModel>, int>(
      (ref, meetingId) =>
          ref.read(meetingWorkspaceRepositoryProvider).getNotes(meetingId),
    );

final meetingMinutesProvider = FutureProvider.autoDispose
    .family<List<MeetingMinutesModel>, int>(
      (ref, meetingId) =>
          ref.read(meetingWorkspaceRepositoryProvider).getMinutes(meetingId),
    );
