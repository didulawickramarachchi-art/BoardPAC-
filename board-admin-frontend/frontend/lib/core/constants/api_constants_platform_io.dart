import 'dart:io';

class ApiConstantsPlatform {
  // Use the public HTTPS endpoint on native devices.
  static String get defaultBaseUrl => Platform.isAndroid
      ? 'https://apds.slpa.lk/api'
      : 'https://apds.slpa.lk/api';
}
