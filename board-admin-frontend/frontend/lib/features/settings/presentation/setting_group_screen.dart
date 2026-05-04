import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/setting_request.dart';
import '../provider/setting_provider.dart';

class SettingGroupScreen extends ConsumerWidget {
  final String group;

  const SettingGroupScreen({super.key, required this.group});

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add / Update $group Setting'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(labelText: 'Setting Key'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Setting Value'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(settingGroupProvider(group).notifier)
                  .save(
                    SettingRequest(
                      settingGroup: group,
                      settingKey: keyController.text.trim(),
                      settingValue: valueController.text.trim(),
                      description: descController.text.trim(),
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(settingGroupProvider(group));

    return Scaffold(
      appBar: AppBar(
        title: Text(group),
        actions: [
          IconButton(
            onPressed: () => _showEditDialog(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: asyncData.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.settingKey),
                subtitle: Text(
                  '${item.settingValue}\n${item.description ?? ''}',
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
        error: (e, _) => Center(child: Text('Failed to load settings: $e')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
