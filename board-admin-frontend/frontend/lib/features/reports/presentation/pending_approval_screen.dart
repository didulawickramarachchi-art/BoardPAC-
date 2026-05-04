import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/report_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(pendingApprovalReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: asyncData.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.paperTitle),
                subtitle: Text(
                  'Meeting: ${item.meetingTitle}\n'
                  'User: ${item.username}',
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
        error: (e, _) =>
            Center(child: Text('Failed to load pending approvals: $e')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
