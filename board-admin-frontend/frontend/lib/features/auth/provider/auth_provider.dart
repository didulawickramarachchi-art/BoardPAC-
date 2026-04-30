import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/auth_repository.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/verify_2fa_request.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  return AuthRepository(dio);
});

class AuthState {
  final bool isLoading;
  final String? error;
  final String? pendingUsername;
  final bool requiresTwoFactor;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.pendingUsername,
    this.requiresTwoFactor = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? pendingUsername,
    bool? requiresTwoFactor,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingUsername: pendingUsername ?? this.pendingUsername,
      requiresTwoFactor: requiresTwoFactor ?? this.requiresTwoFactor,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final SecureStorageService storage;

  AuthNotifier(this.repository, this.storage) : super(const AuthState());

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await repository.login(
        LoginRequest(username: username, password: password),
      );

      if (result.requiresTwoFactor) {
        state = state.copyWith(
          isLoading: false,
          pendingUsername: result.username,
          requiresTwoFactor: true,
        );
        return false;
      }

      if (result.token != null &&
          result.refreshToken != null &&
          result.username != null) {
        await storage.saveTokens(
          accessToken: result.token!,
          refreshToken: result.refreshToken!,
          username: result.username!,
        );
      }

      state = state.copyWith(isLoading: false, requiresTwoFactor: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed');
      return false;
    }
  }

  Future<bool> verifyCode(String code) async {
    final username = state.pendingUsername;
    if (username == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await repository.verify2FA(
        Verify2FARequest(username: username, code: code),
      );

      if (result.token != null &&
          result.refreshToken != null &&
          result.username != null) {
        await storage.saveTokens(
          accessToken: result.token!,
          refreshToken: result.refreshToken!,
          username: result.username!,
        );
      }

      state = const AuthState(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Verification failed');
      return false;
    }
  }

  Future<void> logout() async {
    await storage.clearAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthNotifier(repo, storage);
});
