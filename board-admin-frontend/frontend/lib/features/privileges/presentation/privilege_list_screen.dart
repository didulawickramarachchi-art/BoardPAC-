import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/privilege_provider.dart';
import 'assign_privilege_screen.dart';

class PrivilegeListScreen extends ConsumerWidget {
  const PrivilegeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privilegesAsync = ref.watch(privilegeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privileges'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssignPrivilegeScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: privilegesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No privileges found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.username),
                  subtitle: Text(
                    'Subcategory: ${item.subcategoryName}\nRole: ${item.assignedRole}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(privilegeListProvider.notifier).remove(
                            userId: item.userId,
                            subcategoryId: item.subcategoryId,
                          );
                    },
                  ),
                ),
              );
            },
          );
        },
        error: (error, _) => Center(child: Text('Failed to load privileges: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}