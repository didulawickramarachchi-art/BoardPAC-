import 'package:dio/dio.dart';
import '../model/privilege_model.dart';
import '../model/privilege_request.dart';

class PrivilegeRepository {
  final Dio dio;

  PrivilegeRepository(this.dio);

  Future<List<PrivilegeModel>> getPrivileges() async {
    final response = await dio.get('/privileges');
    return (response.data as List)
        .map((e) => PrivilegeModel.fromJson(e))
        .toList();
  }

  Future<List<PrivilegeModel>> getPrivilegesByUser(int userId) async {
    final response = await dio.get('/privileges/user/$userId');
    return (response.data as List)
        .map((item) => PrivilegeModel.fromJson(item))
        .toList();
  }

  Future<void> assignPrivilege(PrivilegeRequest request) async {
    await dio.post('/privileges', data: request.toJson());
  }

  Future<void> removePrivilege({
    required int userId,
    required int subcategoryId,
  }) async {
    await dio.delete(
      '/privileges',
      queryParameters: {'userId': userId, 'subcategoryId': subcategoryId},
    );
  }
}
