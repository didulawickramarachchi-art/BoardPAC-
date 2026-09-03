import 'dart:io';

class ApiConstantsPlatform {
  // Android emulators expose the development machine through 10.0.2.2.
  // iOS simulators and desktop builds can use localhost directly.
  static String get defaultBaseUrl => Platform.isAndroid
      ? 'http://10.0.2.2:8081/api'
      : 'http://localhost:8081/api';
}
