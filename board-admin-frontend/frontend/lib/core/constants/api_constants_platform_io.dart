import 'dart:io';

class ApiConstantsPlatform {
  // Android emulators reach the host machine through 10.0.2.2.
  // Other native platforms can use localhost directly.
  static String get defaultBaseUrl => Platform.isAndroid
      ? 'https://apds.slpa.lk/api'
      : 'https://apds.slpa.lk/api';
}
