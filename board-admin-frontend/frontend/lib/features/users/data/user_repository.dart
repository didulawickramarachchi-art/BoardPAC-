import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../model/user_model.dart';
import '../model/user_request.dart';

class UserRepository {
  final Dio dio;

  UserRepository(this.dio);

  Future<UserModel> getCurrentUser() async {
    final response = await dio.get('/users/me');
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> uploadProfilePicture({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    final file = filePath != null && filePath.isNotEmpty
        ? await MultipartFile.fromFile(filePath, filename: fileName)
        : MultipartFile.fromBytes(fileBytes ?? Uint8List(0), filename: fileName);
    final response = await dio.post(
      '/users/me/profile-picture',
      data: FormData.fromMap({'file': file}),
    );
    return UserModel.fromJson(response.data);
  }

  Future<Uint8List> getProfilePicture(String url) async {
    final response = await dio.get<List<int>>(
      url,
      // The backend commonly keeps the same URL after a profile-picture
      // update. Force this real network refresh to bypass the browser/HTTP
      // cache; Riverpod caches the returned bytes inside the app afterward.
      queryParameters: {
        'profilePictureVersion': DateTime.now().millisecondsSinceEpoch,
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': 'image/*'},
      ),
    );
    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    if (bytes.isEmpty) {
      throw StateError('The profile picture response was empty.');
    }
    return bytes;
  }

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
