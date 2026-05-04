import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/report_provider.dart';

class UserCategoryReportScreen extends ConsumerWidget {
  const UserCategoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(userCategoryReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('User Category Report')),
      body: asyncData.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.username),
                subtitle: Text(
                  'Category: ${item.categoryName}\n'
                  'Subcategory: ${item.subcategoryName}\n'
                  'Role: ${item.assignedRole}',
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
        error: (e, _) => Center(child: Text('Failed to load report: $e')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
