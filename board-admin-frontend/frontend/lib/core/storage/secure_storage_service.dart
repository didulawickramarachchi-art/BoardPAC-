import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String usernameKey = 'username';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String username,
  }) async {
    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
    await _storage.write(key: usernameKey, value: username);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: refreshTokenKey);
  }

  Future<String?> getUsername() async {
    return _storage.read(key: usernameKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
}
