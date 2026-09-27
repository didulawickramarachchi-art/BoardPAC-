import 'dart:io';

class ApiConstantsPlatform {
  // Android emulators reach the host machine through 10.0.2.2.
  // Other native platforms can use localhost directly.
  static String get defaultBaseUrl => Platform.isAndroid
      ? 'http://10.0.2.2:8081/api'
      : 'http://localhost:8081/api';
}
