import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/device_provider.dart';

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: devicesAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const AppEmptyState(message: 'No devices found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                child: ListTile(
                  title: Text(device.deviceId),
                  subtitle: Text(
                    '${device.deviceInfo ?? 'Unknown device'}\n'
                    'Status: ${device.status ?? '-'}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final notifier = ref.read(deviceListProvider.notifier);
                      if (value == 'approve') await notifier.approve(device.id);
                      if (value == 'deactivate') await notifier.deactivate(device.id);
                      if (value == 'wipe') await notifier.wipe(device.id);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'approve', child: Text('Approve')),
                      PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                      PopupMenuItem(value: 'wipe', child: Text('Wipe')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (error, _) => Center(child: Text('Failed to load devices: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}