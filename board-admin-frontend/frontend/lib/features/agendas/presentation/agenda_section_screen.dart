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
    bool isCreating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setLocalState) => AlertDialog(
          title: const Text('Create Section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) return;
                      setLocalState(() => isCreating = true);
                      try {
                        await ref
                            .read(agendaSectionProvider(meetingId).notifier)
                            .createSection(
                              AgendaSectionRequest(
                                meetingId: meetingId,
                                title: titleController.text.trim(),
                                numberLabel: null,
                                displayOrder: null,
                              ),
                            );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (error) {
                        if (dialogContext.mounted) {
                          setLocalState(() => isCreating = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Could not create section: $error'),
                            ),
                          );
                        }
                      }
                    },
              child: isCreating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
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
      floatingActionButton: access.isSecretary
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

          // Preserve the provider's optimistic drag order while it is saved.
          final sections = [...items];
          if (!access.isSecretary) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length,
              itemBuilder: (context, index) =>
                  _sectionTile(context, ref, access, sections[index], index),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            buildDefaultDragHandles: false,
            itemCount: sections.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final reordered = [...sections];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              ref
                  .read(agendaSectionProvider(meetingId).notifier)
                  .reorder(reordered);
            },
            itemBuilder: (context, index) {
              return ReorderableDragStartListener(
                key: ValueKey(sections[index].id),
                index: index,
                child: _sectionTile(
                  context,
                  ref,
                  access,
                  sections[index],
                  index,
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

  Widget _sectionTile(
    BuildContext context,
    WidgetRef ref,
    RoleAccess access,
    dynamic section,
    int index,
  ) => Card(
    key: ValueKey(section.id),
    child: ListTile(
      leading: CircleAvatar(child: Text('${index + 1}')),
      title: Text(section.title),
      subtitle: const Text('Agenda section'),
      trailing: access.isSecretary
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Delete section',
                  onPressed: () =>
                      _deleteSection(context, ref, section.id, section.title),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                const Icon(Icons.drag_handle),
              ],
            )
          : const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AgendaItemScreen(
            meetingId: meetingId,
            meetingTitle: meetingTitle,
            sectionId: section.id,
            sectionTitle: section.title,
          ),
        ),
      ),
    ),
  );
}
