import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/user_repository.dart';
import '../model/user_model.dart';
import '../model/user_request.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.read(dioProvider);
  return UserRepository(dio);
});

final currentUserProvider = FutureProvider<UserModel>((ref) {
  return ref.read(userRepositoryProvider).getCurrentUser();
});

/// Loads protected profile images through the configured Dio client so the
/// authentication interceptor is applied. This also supports relative URLs
/// returned by the API, which Image.network cannot resolve on its own.
final profilePictureProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, url) {
      return ref.read(userRepositoryProvider).getProfilePicture(url);
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
