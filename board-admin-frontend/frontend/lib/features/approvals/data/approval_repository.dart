import 'package:dio/dio.dart';
import '../model/approval_model.dart';
import '../model/approval_request.dart';

class ApprovalRepository {
  final Dio dio;

  ApprovalRepository(this.dio);

  Future<List<ApprovalModel>> getByPaper(int paperId) async {
    final response = await dio.get('/approvals/paper/$paperId');
    return (response.data as List)
        .map((e) => ApprovalModel.fromJson(e))
        .toList();
  }

  Future<void> submitApproval(ApprovalRequest request) async {
    await dio.post('/approvals', data: request.toJson());
  }
}
