class ApiConstants {
  // Override at build/run time with:
  // --dart-define=API_BASE_URL=https://example.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://boardpac.onrender.com/api',
  );

  // 🔐 Auth
  static const String login = '/auth/login';
  static const String verify2fa = '/auth/verify-2fa';
  static const String refreshToken = '/tokens/refresh';
  static const String filesUpload = '/files/upload';

  // 📊 Dashboard
  static const String dashboardSummary = '/dashboard/summary';
}
