import 'package:dio/dio.dart';

class ApiErrorMessage {
  static String from(Object error, {String fallback = 'Something went wrong'}) {
    if (error is! DioException) {
      return fallback;
    }

    final statusCode = error.response?.statusCode;
    switch (statusCode) {
      case 400:
        return _serverMessage(error) ?? 'The request was not accepted.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to view this content. Sign in again or contact an administrator.';
      case 404:
        return 'The requested data was not found.';
      case 500:
        return 'The server had a problem. Please try again later.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to the server. Check that the API is running.';
    }

    return _serverMessage(error) ?? fallback;
  }

  static String? _serverMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return null;
  }
}
