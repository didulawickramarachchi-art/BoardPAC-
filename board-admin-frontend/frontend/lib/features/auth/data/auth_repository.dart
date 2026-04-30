import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/verify_2fa_request.dart';

class AuthRepository {
  final Dio dio;

  AuthRepository(this.dio) {
    dio.options.baseUrl = ApiConstants.baseUrl;

    dio.options.headers = {'Content-Type': 'application/json'};
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await dio.post('/auth/login', data: request.toJson());

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<LoginResponse> verify2FA(Verify2FARequest request) async {
    try {
      final response = await dio.post(
        '/auth/verify-2fa',
        data: request.toJson(),
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // 🔥 Centralized error handler
  String _handleError(DioException e) {
    if (e.response != null) {
      return e.response?.data['message'] ??
          'Server error (${e.response?.statusCode})';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server';
    } else {
      return 'Unexpected error occurred';
    }
  }
}
