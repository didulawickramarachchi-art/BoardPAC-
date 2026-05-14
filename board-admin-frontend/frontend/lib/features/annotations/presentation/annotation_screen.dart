import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/annotation_request.dart';
import '../model/annotation_restore_request.dart';
import '../provider/annotation_provider.dart';

class AnnotationScreen extends ConsumerWidget {
  final int paperId;
  final int userId;
  final String paperTitle;

  const AnnotationScreen({
    super.key,
    required this.paperId,
    required this.userId,
    required this.paperTitle,
  });

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final dataController = TextEditingController();
    final pageController = TextEditingController();
    String annotationType = 'TEXT_NOTE';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Add Annotation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: annotationType,
                  items: const [
                    DropdownMenuItem(value: 'TEXT_NOTE', child: Text('Text Note')),
                    DropdownMenuItem(value: 'HIGHLIGHT', child: Text('Highlight')),
                    DropdownMenuItem(value: 'DRAWING', child: Text('Drawing')),
                    DropdownMenuItem(value: 'SHAPE', child: Text('Shape')),
                    DropdownMenuItem(value: 'FREEHAND', child: Text('Freehand')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => annotationType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dataController,
                  decoration: const InputDecoration(labelText: 'Annotation JSON/Data'),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pageController,
                  decoration: const InputDecoration(labelText: 'Page Number'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await ref.read(annotationListProvider((paperId: paperId, userId: userId)).notifier).create(
                      AnnotationRequest(
                        paperId: paperId,
                        userId: userId,
                        annotationType: annotationType,
                        annotationDataJson: dataController.text.trim(),
                        pageNumber: int.tryParse(pageController.text.trim()),
                      ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final backup = await ref.read(annotationListProvider((paperId: paperId, userId: userId)).notifier).backup();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup created: ${backup.backupId}')),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final backupIdController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Backup'),
        content: TextField(
          controller: backupIdController,
          decoration: const InputDecoration(labelText: 'Backup ID'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(annotationListProvider((paperId: paperId, userId: userId)).notifier).restore(
                    AnnotationRestoreRequest(
                      backupId: int.parse(backupIdController.text.trim()),
                      userId: userId,
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(annotationListProvider((paperId: paperId, userId: userId)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Annotations - $paperTitle'),
        actions: [
          IconButton(
            onPressed: () => _backup(context, ref),
            icon: const Icon(Icons.backup_outlined),
          ),
          IconButton(
            onPressed: () => _restore(context, ref),
            icon: const Icon(Icons.restore_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.edit_note),
      ),
      body: asyncData.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No annotations found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.annotationType),
                  subtitle: Text('Page: ${item.pageNumber ?? '-'}\n${item.annotationDataJson}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
        error: (e, _) => Center(child: Text('Failed to load annotations: $e')),
        loading: () => const AppLoading(),
      ),
    );
  }
}