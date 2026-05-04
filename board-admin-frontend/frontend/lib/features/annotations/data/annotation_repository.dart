import 'package:dio/dio.dart';
import '../model/annotation_backup_model.dart';
import '../model/annotation_model.dart';
import '../model/annotation_request.dart';
import '../model/annotation_restore_request.dart';

class AnnotationRepository {
  final Dio dio;

  AnnotationRepository(this.dio);

  Future<List<AnnotationModel>> getByPaperAndUser(int paperId, int userId) async {
    final response = await dio.get('/annotations/paper/$paperId/user/$userId');
    return (response.data as List)
        .map((e) => AnnotationModel.fromJson(e))
        .toList();
  }

  Future<void> create(AnnotationRequest request) async {
    await dio.post('/annotations', data: request.toJson());
  }

  Future<AnnotationBackupModel> backup(int userId) async {
    final response = await dio.post('/annotations/backup/$userId');
    return AnnotationBackupModel.fromJson(response.data);
  }

  Future<void> restore(AnnotationRestoreRequest request) async {
    await dio.post('/annotations/restore', data: request.toJson());
  }
}