import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../provider/report_provider.dart';

class LoginHistoryScreen extends ConsumerWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(loginHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Login History')),
      body: asyncData.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.username),
                subtitle: Text('${item.loginTime}\n${item.deviceInfo ?? '-'}'),
                isThreeLine: true,
                trailing: AppStatusChip(label: item.status),
              ),
            );
          },
        ),
        error: (e, _) =>
            Center(child: Text('Failed to load login history: $e')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
