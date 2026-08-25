import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/setting_repository.dart';
import '../model/setting_model.dart';
import '../model/setting_request.dart';

final settingRepositoryProvider = Provider<SettingRepository>((ref) {
  return SettingRepository(ref.read(dioProvider));
});

final settingGroupProvider =
    StateNotifierProvider.family<
      SettingNotifier,
      AsyncValue<List<SettingModel>>,
      String
    >((ref, group) {
      return SettingNotifier(ref.read(settingRepositoryProvider), group)
        ..load();
    });

class SettingNotifier extends StateNotifier<AsyncValue<List<SettingModel>>> {
  final SettingRepository repository;
  final String group;

  SettingNotifier(this.repository, this.group) : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getByGroup(group);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> save(SettingRequest request) async {
    await repository.save(request);
    await load();
  }

  Future<void> saveAll(List<SettingRequest> requests) async {
    for (final request in requests) {
      await repository.save(request);
    }
    await load();
  }
}
