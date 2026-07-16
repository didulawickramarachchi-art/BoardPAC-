import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/auth_repository.dart';
import '../model/login_request.dart';
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

  final int? userId;
  final String? username;
  final String? role;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.pendingUsername,
    this.requiresTwoFactor = false,
    this.userId,
    this.username,
    this.role,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? pendingUsername,
    bool? requiresTwoFactor,
    int? userId,
    String? username,
    String? role,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingUsername: pendingUsername ?? this.pendingUsername,
      requiresTwoFactor: requiresTwoFactor ?? this.requiresTwoFactor,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      role: role ?? this.role,
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

      if (result.isDeactivated) {
        await storage.clearAll();
        state = state.copyWith(
          isLoading: false,
          error: 'Your account has been deactivated. Contact an administrator.',
          requiresTwoFactor: false,
        );
        return false;
      }

      if (result.requiresTwoFactor) {
        state = state.copyWith(
          isLoading: false,
          pendingUsername: result.username,
          requiresTwoFactor: true,
          userId: result.userId,
          username: result.username,
          role: result.role?.toUpperCase() ?? 'MEMBER',
        );
        return false;
      }

      if (result.token != null && result.username != null) {
        await storage.saveTokens(
          accessToken: result.token!,
          refreshToken: result.refreshToken ?? '',
          username: result.username!,
        );
      }

      state = state.copyWith(
        isLoading: false,
        requiresTwoFactor: false,
        userId: result.userId,
        username: result.username ?? username,
        role: result.role?.toUpperCase() ?? 'MEMBER',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed',
      );
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

      if (result.isDeactivated) {
        await storage.clearAll();
        state = const AuthState(
          error: 'Your account has been deactivated. Contact an administrator.',
        );
        return false;
      }

      if (result.token != null && result.username != null) {
        await storage.saveTokens(
          accessToken: result.token!,
          refreshToken: result.refreshToken ?? '',
          username: result.username!,
        );
      }

      state = AuthState(
        isLoading: false,
        userId: result.userId,
        username: result.username ?? username,
        role: result.role?.toUpperCase() ?? 'MEMBER',
        requiresTwoFactor: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verification failed',
      );
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
