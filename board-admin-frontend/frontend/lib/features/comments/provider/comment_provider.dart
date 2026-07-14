import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/comment_repository.dart';
import '../model/comment_model.dart';
import '../model/comment_request.dart';
import '../model/share_comment_request.dart';
import '../model/share_paper_request.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.read(dioProvider));
});

final paperCommentProvider = StateNotifierProvider.family<
    CommentNotifier, AsyncValue<List<CommentModel>>, int>((ref, paperId) {
  return CommentNotifier.paper(ref.read(commentRepositoryProvider), paperId)..load();
});

final meetingCommentProvider = StateNotifierProvider.family<
    MeetingCommentNotifier, AsyncValue<List<CommentModel>>, int>((ref, meetingId) {
  return MeetingCommentNotifier(ref.read(commentRepositoryProvider), meetingId)..load();
});

class CommentNotifier extends StateNotifier<AsyncValue<List<CommentModel>>> {
  final CommentRepository repository;
  final int paperId;

  CommentNotifier.paper(this.repository, this.paperId) : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getByPaper(paperId);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addComment(CommentRequest request) async {
    await repository.createComment(request);
    await load();
  }

  Future<void> react(int commentId, String reactionType) async {
    await repository.react(commentId, reactionType);
    await load();
  }

  Future<void> shareComment(ShareCommentRequest request) async {
    await repository.shareComment(request);
    await load();
  }

  Future<void> sharePaper(SharePaperRequest request) async {
    await repository.sharePaper(request);
    await load();
  }
}

class MeetingCommentNotifier extends StateNotifier<AsyncValue<List<CommentModel>>> {
  final CommentRepository repository;
  final int meetingId;

  MeetingCommentNotifier(this.repository, this.meetingId) : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getByMeeting(meetingId);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addComment(CommentRequest request) async {
    await repository.createComment(request);
    await load();
  }
}
