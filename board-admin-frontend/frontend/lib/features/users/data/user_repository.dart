import 'package:dio/dio.dart';
import '../model/user_model.dart';
import '../model/user_request.dart';

class UserRepository {
  final Dio dio;

  UserRepository(this.dio);

  Future<List<UserModel>> getUsers() async {
    final response = await dio.get('/users');
    return (response.data as List)
        .map((e) => UserModel.fromJson(e))
        .toList();
  }

  Future<UserModel> updateUser(int id, UserRequest request) async {
    final response = await dio.put('/users/$id', data: request.toJson());
    return UserModel.fromJson(response.data);
  }

  Future<void> deactivateUser(int id) async {
    await dio.put('/users/$id/deactivate');
  }

  Future<void> activateUser(int id) async {
    await dio.put('/users/$id/activate');
  }

  Future<void> lockUser(int id) async {
    await dio.put('/users/$id/lock');
  }

  Future<void> unlockUser(int id) async {
    await dio.put('/users/$id/unlock');
  }

  Future<void> resetPassword(int id) async {
    await dio.put('/users/$id/reset-password');
  }
}