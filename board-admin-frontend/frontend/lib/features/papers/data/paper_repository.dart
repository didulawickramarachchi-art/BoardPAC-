import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../model/attachment_model.dart';
import '../model/attachment_request.dart';
import '../model/paper_model.dart';
import '../model/paper_request.dart';

class PaperRepository {
  final Dio dio;

  PaperRepository(this.dio);

  Future<List<PaperModel>> getAllPapers() async {
    final response = await dio.get('/papers');
    return (response.data as List).map((e) => PaperModel.fromJson(e)).toList();
  }

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

  Future<void> reactToAttachment(int attachmentId, String reactionType) async {
    await dio.post(
      '/attachments/$attachmentId/reaction',
      data: {'reactionType': reactionType},
    );
  }

  Future<String> uploadAttachment({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': filePath != null && filePath.isNotEmpty
          ? await MultipartFile.fromFile(filePath, filename: fileName)
          : MultipartFile.fromBytes(
              fileBytes ?? Uint8List(0),
              filename: fileName,
            ),
    });

    final response = await dio.post(
      ApiConstants.filesUpload,
      data: formData,
      onSendProgress: onProgress,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    return resolveUploadedFilePath(response.data);
  }

  String resolveUploadedFilePath(dynamic data) {
    if (data is String) {
      return data;
    }

    if (data is Map) {
      for (final key in ['filePath', 'fileUrl', 'url', 'path', 'publicUrl']) {
        final value = data[key];
        if (value != null) {
          return value.toString();
        }
      }
    }

    return data?.toString() ?? '';
  }
}
