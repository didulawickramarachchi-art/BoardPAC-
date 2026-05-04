import 'package:dio/dio.dart';
import '../model/attachment_model.dart';
import '../model/attachment_request.dart';
import '../model/paper_model.dart';
import '../model/paper_request.dart';

class PaperRepository {
  final Dio dio;

  PaperRepository(this.dio);

  Future<List<PaperModel>> getPapersByMeeting(int meetingId) async {
    final response = await dio.get('/papers/meeting/$meetingId');
    return (response.data as List).map((e) => PaperModel.fromJson(e)).toList();
  }

  Future<void> createPaper(PaperRequest request) async {
    await dio.post('/papers', data: request.toJson());
  }

  Future<List<AttachmentModel>> getAttachments(int paperId) async {
    final response = await dio.get('/attachments/paper/$paperId');
    return (response.data as List)
        .map((e) => AttachmentModel.fromJson(e))
        .toList();
  }

  Future<void> addAttachment(AttachmentRequest request) async {
    await dio.post('/attachments', data: request.toJson());
  }
}
