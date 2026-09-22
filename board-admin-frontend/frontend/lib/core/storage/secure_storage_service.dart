import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String usernameKey = 'username';
  String? _accessTokenCache;
  String? _refreshTokenCache;
  String? _usernameCache;
  bool _accessTokenLoaded = false;
  bool _refreshTokenLoaded = false;
  bool _usernameLoaded = false;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String username,
  }) async {
    _accessTokenCache = accessToken;
    _refreshTokenCache = refreshToken;
    _usernameCache = username;
    _accessTokenLoaded = _refreshTokenLoaded = _usernameLoaded = true;
    await Future.wait([
      _storage.write(key: accessTokenKey, value: accessToken),
      _storage.write(key: refreshTokenKey, value: refreshToken),
      _storage.write(key: usernameKey, value: username),
    ]);
  }

  Future<String?> getAccessToken() async {
    if (!_accessTokenLoaded) {
      _accessTokenCache = await _storage.read(key: accessTokenKey);
      _accessTokenLoaded = true;
    }
    return _accessTokenCache;
  }

  Future<String?> getRefreshToken() async {
    if (!_refreshTokenLoaded) {
      _refreshTokenCache = await _storage.read(key: refreshTokenKey);
      _refreshTokenLoaded = true;
    }
    return _refreshTokenCache;
  }

  Future<String?> getUsername() async {
    if (!_usernameLoaded) {
      _usernameCache = await _storage.read(key: usernameKey);
      _usernameLoaded = true;
    }
    return _usernameCache;
  }

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> updateTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessTokenCache = accessToken;
    _accessTokenLoaded = true;
    await _storage.write(key: accessTokenKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshTokenCache = refreshToken;
      _refreshTokenLoaded = true;
      await _storage.write(key: refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clearAuth() async {
    _clearCache();
    await Future.wait([
      _storage.delete(key: accessTokenKey),
      _storage.delete(key: refreshTokenKey),
      _storage.delete(key: usernameKey),
    ]);
  }

  /// Kept for callers that explicitly need a full application reset.
  Future<void> clearAll() {
    _clearCache();
    return _storage.deleteAll();
  }

  void _clearCache() {
    _accessTokenCache = _refreshTokenCache = _usernameCache = null;
    _accessTokenLoaded = _refreshTokenLoaded = _usernameLoaded = true;
  }
}
