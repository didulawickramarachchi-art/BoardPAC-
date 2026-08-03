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
      throw AuthException(_handleError(e));
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
      throw AuthException(_handleError(e));
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await dio.post(
        '/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw AuthException(_handleError(e));
    }
  }

  Future<void> requestPasswordReset({
    required String email,
    required String resetUrl,
  }) async {
    try {
      await dio.post(
        '/auth/password-reset/request',
        data: {'email': email, 'resetUrl': resetUrl},
      );
    } on DioException catch (e) {
      throw AuthException(_handleError(e));
    }
  }

  // 🔥 Centralized error handler
  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'] ?? data['detail'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      return 'Server error (${e.response?.statusCode})';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server';
    } else {
      return 'Unexpected error occurred';
    }
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
