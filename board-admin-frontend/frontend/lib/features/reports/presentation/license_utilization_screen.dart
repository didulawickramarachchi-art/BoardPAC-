import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_info_tile.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/report_provider.dart';

class LicenseUtilizationScreen extends ConsumerWidget {
  const LicenseUtilizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(licenseUtilizationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('License Utilization')),
      body: asyncData.when(
        data: (item) => Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AppInfoTile(
                    title: 'Total Users',
                    value: item.totalUsers.toString(),
                  ),
                  AppInfoTile(
                    title: 'Active Users',
                    value: item.activeUsers.toString(),
                  ),
                  AppInfoTile(
                    title: 'Deactivated Users',
                    value: item.deactivatedUsers.toString(),
                  ),
                  AppInfoTile(
                    title: 'Locked Users',
                    value: item.lockedUsers.toString(),
                  ),
                  AppInfoTile(
                    title: 'Deleted Users',
                    value: item.deletedUsers.toString(),
                  ),
                ],
              ),
            ),
          ),
        ),
        error: (e, _) =>
            Center(child: Text('Failed to load license utilization: $e')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
