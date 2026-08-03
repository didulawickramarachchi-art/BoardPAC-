import '../../../core/device/device_identity.dart';

class Verify2FARequest {
  final String username;
  final String code;
  final DeviceIdentity device;

  Verify2FARequest({
    required this.username,
    required this.code,
    required this.device,
  });

  Map<String, dynamic> toJson() {
    return {'username': username, 'code': code, ...device.toJson()};
  }
}
