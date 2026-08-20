import 'dart:math';

import 'package:flutter/foundation.dart';

import '../storage/secure_storage_service.dart';

/// Identifies this app installation/browser profile to the authentication API.
///
/// The server must use [deviceId] as one input to its device approval check. It
/// must not treat the client supplied device information as proof of approval.
class DeviceIdentity {
  final String deviceId;
  final String deviceInfo;
  final String boardPacVersion;
  final String osVersion;
  final String description;

  const DeviceIdentity({
    required this.deviceId,
    required this.deviceInfo,
    required this.boardPacVersion,
    required this.osVersion,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceInfo': deviceInfo,
    'boardPacVersion': boardPacVersion,
    'osVersion': osVersion,
    'description': description,
  };
}

class DeviceIdentityService {
  static const _deviceIdKey = 'device_installation_id';
  static const _appVersion = '1.0.0';

  final SecureStorageService storage;

  DeviceIdentityService(this.storage);

  Future<DeviceIdentity> getIdentity({required String username}) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      throw ArgumentError.value(username, 'username', 'must not be empty');
    }

    // An approval is for a user on an installation. Keep a stable identity for
    // each account so two users of the same device receive separate requests.
    final storageKey =
        '$_deviceIdKey:${Uri.encodeComponent(normalizedUsername)}';
    var deviceId = await storage.read(storageKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _newInstallationId();
      await storage.write(storageKey, deviceId);
    }

    final platform = kIsWeb ? 'Web' : _platformName(defaultTargetPlatform);
    return DeviceIdentity(
      deviceId: deviceId,
      deviceInfo: kIsWeb ? '$platform browser' : '$platform device',
      boardPacVersion: _appVersion,
      osVersion: platform,
      description: 'BoardPAC ${kIsWeb ? 'web' : 'app'} installation',
    );
  }

  String _newInstallationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    // UUID v4 variant bits make the generated identifier easy to recognize.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String _platformName(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }
}
