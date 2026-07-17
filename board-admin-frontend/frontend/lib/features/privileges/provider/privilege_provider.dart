import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/privilege_repository.dart';
import '../model/privilege_model.dart';
import '../model/privilege_request.dart';

final privilegeRepositoryProvider = Provider<PrivilegeRepository>((ref) {
  return PrivilegeRepository(ref.read(dioProvider));
});

final privilegeListProvider =
    StateNotifierProvider<PrivilegeNotifier, AsyncValue<List<PrivilegeModel>>>((ref) {
  return PrivilegeNotifier(ref.read(privilegeRepositoryProvider))..load();
});

class PrivilegeNotifier extends StateNotifier<AsyncValue<List<PrivilegeModel>>> {
  final PrivilegeRepository repository;

  PrivilegeNotifier(this.repository) : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getPrivileges();
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> assign(PrivilegeRequest request) async {
    await repository.assignPrivilege(request);
    await load();
  }

  Future<void> assignUserToCategory({
    required int userId,
    required Iterable<int> subcategoryIds,
    String assignedRole = 'MEMBER',
  }) async {
    final existingIds = (state.valueOrNull ?? const <PrivilegeModel>[])
        .where((item) => item.userId == userId)
        .map((item) => item.subcategoryId)
        .toSet();
    for (final subcategoryId in subcategoryIds) {
      if (existingIds.contains(subcategoryId)) continue;
      await repository.assignPrivilege(
        PrivilegeRequest(
          userId: userId,
          subcategoryId: subcategoryId,
          assignedRole: assignedRole,
        ),
      );
    }
    await load();
  }

  Future<void> removeUserFromCategory({
    required int userId,
    required Iterable<int> subcategoryIds,
  }) async {
    final assignedIds = (state.valueOrNull ?? const <PrivilegeModel>[])
        .where((item) => item.userId == userId)
        .map((item) => item.subcategoryId)
        .toSet();
    for (final subcategoryId in subcategoryIds) {
      if (!assignedIds.contains(subcategoryId)) continue;
      await repository.removePrivilege(
        userId: userId,
        subcategoryId: subcategoryId,
      );
    }
    await load();
  }

  Future<void> remove({
    required int userId,
    required int subcategoryId,
  }) async {
    await repository.removePrivilege(userId: userId, subcategoryId: subcategoryId);
    await load();
  }
}
