import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/agenda_section_request.dart';
import '../provider/agenda_provider.dart';
import 'agenda_item_screen.dart';

class AgendaSectionScreen extends ConsumerWidget {
  final int meetingId;
  final String meetingTitle;

  const AgendaSectionScreen({
    super.key,
    required this.meetingId,
    required this.meetingTitle,
  });

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final numberController = TextEditingController();
    final orderController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Section'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(agendaSectionProvider(meetingId).notifier)
                  .createSection(
                    AgendaSectionRequest(
                      meetingId: meetingId,
                      title: titleController.text.trim(),
                      numberLabel: numberController.text.trim(),
                      displayOrder: orderController.text.trim().isEmpty
                          ? null
                          : int.parse(orderController.text.trim()),
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSection(
    BuildContext context,
    WidgetRef ref,
    int id,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete agenda section?'),
        content: Text(
          'Delete "$title"? Its agenda items will be kept as unassigned items.',
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
      await ref
          .read(agendaSectionProvider(meetingId).notifier)
          .deleteSection(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda section deleted.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMessage.from(
                error,
                fallback: 'Could not delete agenda section.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(agendaSectionProvider(meetingId));
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile);

    return Scaffold(
      appBar: AppBar(title: Text('Agenda Sections - $meetingTitle')),
      floatingActionButton: access.canManageMeetings
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: sectionsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No sections found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final section = items[index];
              return Card(
                child: ListTile(
                  title: Text(section.title),
                  subtitle: Text(section.numberLabel ?? ''),
                  trailing: access.canManageMeetings
                      ? IconButton(
                          tooltip: 'Delete section',
                          onPressed: () => _deleteSection(
                            context,
                            ref,
                            section.id,
                            section.title,
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AgendaItemScreen(
                          meetingId: meetingId,
                          meetingTitle: meetingTitle,
                          sectionId: section.id,
                          sectionTitle: section.title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load sections: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
