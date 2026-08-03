import '../../../core/device/device_identity.dart';

class LoginRequest {
  final String username;
  final String password;
  final DeviceIdentity device;

  LoginRequest({
    required this.username,
    required this.password,
    required this.device,
  });

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password, ...device.toJson()};
  }
}
