import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../provider/report_provider.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(auditLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: asyncData.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text('${item.moduleName} - ${item.actionName}'),
                subtitle: Text(
                  '${item.username}\n${item.actionTime}\n${item.parameters ?? ''}',
                ),
                isThreeLine: true,
                trailing: AppStatusChip(label: item.level),
              ),
            );
          },
        ),
        error: (e, _) => Center(child: Text('Failed to load audit logs: $e')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
