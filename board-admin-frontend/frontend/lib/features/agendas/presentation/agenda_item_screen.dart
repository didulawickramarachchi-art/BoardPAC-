import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/agenda_item_request.dart';
import '../provider/agenda_provider.dart';

class AgendaItemScreen extends ConsumerWidget {
  final int meetingId;
  final String meetingTitle;
  final int? sectionId;
  final String? sectionTitle;

  const AgendaItemScreen({
    super.key,
    required this.meetingId,
    required this.meetingTitle,
    this.sectionId,
    this.sectionTitle,
  });

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final numberController = TextEditingController();
    final orderController = TextEditingController();
    final descController = TextEditingController();
    String itemType = 'PAPER';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Create Agenda Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: itemType,
                  items: const [
                    DropdownMenuItem(value: 'HEADING', child: Text('Heading')),
                    DropdownMenuItem(
                      value: 'SUB_HEADING',
                      child: Text('Sub Heading'),
                    ),
                    DropdownMenuItem(value: 'PAPER', child: Text('Paper')),
                    DropdownMenuItem(value: 'AUDIO', child: Text('Audio')),
                    DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => itemType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Number Label'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(labelText: 'Display Order'),
                  keyboardType: TextInputType.number,
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
                    .read(agendaItemProvider(meetingId).notifier)
                    .createItem(
                      AgendaItemRequest(
                        meetingId: meetingId,
                        sectionId: sectionId,
                        itemType: itemType,
                        title: titleController.text.trim(),
                        numberLabel: numberController.text.trim(),
                        displayOrder: orderController.text.trim().isEmpty
                            ? null
                            : int.parse(orderController.text.trim()),
                        description: descController.text.trim(),
                        mediaPath: null,
                      ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(agendaItemProvider(meetingId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda Items - ${sectionTitle ?? meetingTitle}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No agenda items found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.itemType} • ${item.numberLabel ?? ''}',
                  ),
                ),
              );
            },
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load agenda items: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
