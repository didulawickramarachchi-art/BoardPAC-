import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
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
                  initialValue: itemType,
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

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    int id,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete agenda item?'),
        content: Text(
          'Delete "$title"? Linked board papers will remain in the meeting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(agendaItemProvider(meetingId).notifier).deleteItem(id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Agenda item deleted.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMessage.from(
                error,
                fallback: 'Could not delete agenda item.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(agendaItemProvider(meetingId));
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');

    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda Items - ${sectionTitle ?? meetingTitle}'),
      ),
      floatingActionButton: access.canManageMeetings
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
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
                  trailing: access.canManageMeetings
                      ? IconButton(
                          tooltip: 'Delete agenda item',
                          onPressed: () =>
                              _deleteItem(context, ref, item.id, item.title),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                        )
                      : null,
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
