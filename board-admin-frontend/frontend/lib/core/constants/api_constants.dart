import 'package:flutter/foundation.dart';

class ApiConstants {
  // 🔥 Base URL (auto switch)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8081/api'; // Web
    } else {
      return 'http://10.0.2.2:8081/api'; // Android emulator
      // If testing on real device, replace with your PC IP:
      // return 'http://192.168.1.100:8081/api';
    }
  }

  // 🔐 Auth
  static const String login = '/auth/login';
  static const String verify2fa = '/auth/verify-2fa';
  static const String refreshToken = '/tokens/refresh';
  static const String filesUpload = '/files/upload';

  // 📊 Dashboard
  static const String dashboardSummary = '/dashboard/summary';
}
