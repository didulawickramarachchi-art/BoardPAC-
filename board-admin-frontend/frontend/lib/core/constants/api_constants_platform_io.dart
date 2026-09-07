import 'dart:io';

class ApiConstantsPlatform {
  // Android development uses `adb reverse tcp:8081 tcp:8081`, avoiding host
  // firewall and emulator DNS issues. Other native platforms use localhost.
  static String get defaultBaseUrl => Platform.isAndroid
      ? 'http://127.0.0.1:8081/api'
      : 'http://localhost:8081/api';
}
