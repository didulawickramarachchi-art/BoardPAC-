import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/user_repository.dart';
import '../model/user_model.dart';
import '../model/user_request.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.read(dioProvider);
  return UserRepository(dio);
});

final currentUserProvider = FutureProvider<UserModel>((ref) {
  // Re-fetch /users/me whenever a different account logs in. Without this
  // dependency Riverpod can keep the previous account's UserModel cached.
  ref.watch(
    authProvider.select((auth) => (auth.userId, auth.username)),
  );
  return ref.read(userRepositoryProvider).getCurrentUser();
});

/// Loads protected profile images through the configured Dio client and keeps
/// the downloaded bytes cached for the lifetime of the app. The user ID is
/// part of the key so accounts never share an image when the API returns the
/// same relative URL for multiple users.
final profilePictureProvider =
    FutureProvider.family<Uint8List, ({int userId, String url})>((ref, request) {
      return ref.read(userRepositoryProvider).getProfilePicture(request.url);
    });

final userListProvider =
    StateNotifierProvider.autoDispose<
      UserNotifier,
      AsyncValue<List<UserModel>>
    >((ref) {
      return UserNotifier(ref.read(userRepositoryProvider))..loadUsers();
    });

class UserNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final UserRepository repository;

  UserNotifier(this.repository) : super(const AsyncLoading());

  Future<void> loadUsers() async {
    try {
      final users = await repository.getUsers();
      state = AsyncData(users);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateUser(int id, UserRequest request) async {
    await repository.updateUser(id, request);
    await loadUsers();
  }

  Future<void> deactivateUser(int id) async {
    await repository.deactivateUser(id);
    await loadUsers();
  }

  Future<void> activateUser(int id) async {
    await repository.activateUser(id);
    await loadUsers();
  }

  Future<void> lockUser(int id) async {
    await repository.lockUser(id);
    await loadUsers();
  }

  Future<void> unlockUser(int id) async {
    await repository.unlockUser(id);
    await loadUsers();
  }

  Future<void> resetPassword(int id) async {
    await repository.resetPassword(id);
    await loadUsers();
  }
}
