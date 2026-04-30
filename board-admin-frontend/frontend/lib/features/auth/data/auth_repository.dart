import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/verify_2fa_request.dart';

class AuthRepository {
  final Dio dio;

  AuthRepository(this.dio);

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await dio.post(ApiConstants.login, data: request.toJson());
    return LoginResponse.fromJson(response.data);
  }

  Future<LoginResponse> verify2FA(Verify2FARequest request) async {
    final response = await dio.post(
      ApiConstants.verify2fa,
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data);
  }
}
