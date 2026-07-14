import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/paper_repository.dart';
import '../model/attachment_model.dart';
import '../model/attachment_request.dart';
import '../model/paper_model.dart';
import '../model/paper_request.dart';
import '../../../core/network/api_error_message.dart';
import 'package:dio/dio.dart';

final paperRepositoryProvider = Provider<PaperRepository>((ref) {
  return PaperRepository(ref.read(dioProvider));
});

final allPaperListProvider = FutureProvider<List<PaperModel>>((ref) async {
  return ref.read(paperRepositoryProvider).getAllPapers();
});

final paperListProvider =
    StateNotifierProvider.family<
      PaperNotifier,
      AsyncValue<List<PaperModel>>,
      int
    >((ref, meetingId) {
      return PaperNotifier(ref.read(paperRepositoryProvider), meetingId)
        ..load();
    });

class PaperNotifier extends StateNotifier<AsyncValue<List<PaperModel>>> {
  final PaperRepository repository;
  final int meetingId;

  PaperNotifier(this.repository, this.meetingId) : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getPapersByMeeting(meetingId);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> createPaper(PaperRequest request) async {
    try {
      await repository.createPaper(request);
      await load();
    } catch (e) {
      if (e is DioException) {
        throw Exception(ApiErrorMessage.from(e, fallback: 'Failed to create paper'));
      }
      rethrow;
    }
  }
}

final attachmentListProvider =
    StateNotifierProvider.family<
      AttachmentNotifier,
      AsyncValue<List<AttachmentModel>>,
      int
    >((ref, paperId) {
      return AttachmentNotifier(ref.read(paperRepositoryProvider), paperId)
        ..load();
    });

class AttachmentNotifier
    extends StateNotifier<AsyncValue<List<AttachmentModel>>> {
  final PaperRepository repository;
  final int paperId;

  AttachmentNotifier(this.repository, this.paperId)
    : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getAttachments(paperId);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addAttachment(AttachmentRequest request) async {
    await repository.addAttachment(request);
    await load();
  }

  Future<void> react(int attachmentId, String reactionType) async {
    await repository.reactToAttachment(attachmentId, reactionType);
    await load();
  }
}
