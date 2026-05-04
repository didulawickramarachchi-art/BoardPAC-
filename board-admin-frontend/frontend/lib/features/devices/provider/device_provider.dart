import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/device_repository.dart';
import '../model/device_model.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.read(dioProvider));
});

final deviceListProvider =
    StateNotifierProvider<DeviceNotifier, AsyncValue<List<DeviceModel>>>((ref) {
  return DeviceNotifier(ref.read(deviceRepositoryProvider))..loadDevices();
});

class DeviceNotifier extends StateNotifier<AsyncValue<List<DeviceModel>>> {
  final DeviceRepository repository;

  DeviceNotifier(this.repository) : super(const AsyncLoading());

  Future<void> loadDevices() async {
    try {
      final items = await repository.getDevices();
      state = AsyncData(items);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> approve(int id) async {
    await repository.approveDevice(id);
    await loadDevices();
  }

  Future<void> deactivate(int id) async {
    await repository.deactivateDevice(id);
    await loadDevices();
  }

  Future<void> wipe(int id) async {
    await repository.wipeDevice(id);
    await loadDevices();
  }
}