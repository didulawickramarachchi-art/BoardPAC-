import 'dart:io';

class ApiConstantsPlatform {
  // Android development uses `adb reverse tcp:8081 tcp:8081`, avoiding host
  // firewall and emulator DNS issues. Other native platforms use localhost.
  static String get defaultBaseUrl => Platform.isAndroid
      ? 'https://pajamas-penalize-posing.ngrok-free.dev/api'
      : 'https://pajamas-penalize-posing.ngrok-free.dev/api';
}
