import 'package:flutter/foundation.dart';

import 'api_constants_platform_stub.dart'
    if (dart.library.io) 'api_constants_platform_io.dart';

class ApiConstants {
  // Override at build/run time with:
  // --dart-define=API_BASE_URL=https://example.com/api
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Use the environment value when provided, otherwise pick a sensible
  // platform-specific default (Android emulator => 10.0.2.2, others => localhost).
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return ApiConstantsPlatform.defaultBaseUrl;
  }

  // 🔐 Auth
  static const String login = '/auth/login';
  static const String verify2fa = '/auth/verify-2fa';
  static const String refreshToken = '/tokens/refresh';
  static const String filesUpload = '/files/upload';

  // 📊 Dashboard
  static const String dashboardSummary = '/dashboard/summary';
}
