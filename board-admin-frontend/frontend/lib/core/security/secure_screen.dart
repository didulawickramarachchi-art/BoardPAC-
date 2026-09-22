import 'package:flutter/services.dart';

/// Controls operating-system screen capture protection where the platform
/// supports it. Calls are intentionally best-effort on unsupported platforms.
abstract final class SecureScreen {
  static const _channel = MethodChannel('board_pac/secure_screen');

  static Future<void> enable() => _setProtected(true);

  static Future<void> disable() => _setProtected(false);

  static Future<void> _setProtected(bool protected) async {
    try {
      await _channel.invokeMethod<void>('setProtected', {
        'protected': protected,
      });
    } on MissingPluginException {
      // Screen-capture blocking is not available on this platform.
    } on PlatformException {
      // Never prevent the document reader from opening if the OS rejects it.
    }
  }
}
