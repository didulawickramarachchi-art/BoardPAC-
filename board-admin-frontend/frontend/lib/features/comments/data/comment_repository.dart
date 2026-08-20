import 'package:dio/dio.dart';
import '../model/comment_model.dart';
import '../model/comment_request.dart';
import '../model/share_comment_request.dart';
import '../model/share_paper_request.dart';

class CommentRepository {
  final Dio dio;

  CommentRepository(this.dio);

  Future<List<CommentModel>> getByPaper(int paperId) async {
    final response = await dio.get('/comments/paper/$paperId');
    return (response.data as List)
        .map((e) => CommentModel.fromJson(e))
        .toList();
  }

  Future<List<CommentModel>> getByMeeting(int meetingId) async {
    final response = await dio.get('/comments/meeting/$meetingId');
    return (response.data as List)
        .map((e) => CommentModel.fromJson(e))
        .toList();
  }

  Future<void> createComment(CommentRequest request) async {
    await dio.post('/comments', data: request.toJson());
  }

  Future<void> react(int commentId, String reactionType) async {
    await dio.post(
      '/comments/$commentId/reaction',
      data: {'reactionType': reactionType},
    );
  }

  Future<void> reply(int commentId, String message) async {
    await dio.post('/comments/$commentId/replies', data: {'message': message});
  }

  Future<void> shareComment(ShareCommentRequest request) async {
    await dio.post('/comments/share', data: request.toJson());
  }

  Future<void> sharePaper(SharePaperRequest request) async {
    await dio.post('/papers/share', data: request.toJson());
  }
}
