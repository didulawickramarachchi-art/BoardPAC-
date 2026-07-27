import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService storageService;
  Future<String?>? _activeRefresh;

  AuthInterceptor(this.storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicRequest(options.path)) {
      final token = await storageService.getAccessToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final shouldRefresh =
        error.response?.statusCode == 401 &&
        !_isPublicRequest(request.path) &&
        request.extra['retriedAfterTokenRefresh'] != true;

    if (!shouldRefresh) {
      handler.next(error);
      return;
    }

    try {
      final token = await (_activeRefresh ??= _refreshAccessToken());
      _activeRefresh = null;

      if (token == null || token.isEmpty) {
        await storageService.clearAll();
        handler.next(error);
        return;
      }

      request.headers['Authorization'] = 'Bearer $token';
      request.extra['retriedAfterTokenRefresh'] = true;

      final retryClient = Dio(
        BaseOptions(
          baseUrl: request.baseUrl,
          connectTimeout: request.connectTimeout,
          receiveTimeout: request.receiveTimeout,
          sendTimeout: request.sendTimeout,
        ),
      );
      final response = await retryClient.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      _activeRefresh = null;
      await storageService.clearAll();
      handler.next(error);
    }
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final client = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    final response = await client.post<dynamic>(
      ApiConstants.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    final data = response.data;
    if (data is! Map) return null;

    final accessToken =
        data['accessToken']?.toString() ?? data['token']?.toString();
    final nextRefreshToken = data['refreshToken']?.toString();
    if (accessToken == null || accessToken.isEmpty) return null;

    await storageService.updateTokens(
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
    );
    return accessToken;
  }

  bool _isPublicRequest(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/verify-2fa') ||
        path.contains('/auth/reset-password') ||
        path.contains('/auth/password-reset') ||
        path.contains(ApiConstants.refreshToken);
  }
}
