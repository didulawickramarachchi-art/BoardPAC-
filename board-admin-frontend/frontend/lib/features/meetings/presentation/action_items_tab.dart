import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/meeting_participant_model.dart';
import '../provider/action_item_provider.dart';

class ActionItemsTab extends ConsumerWidget {
  final int meetingId;
  final List<MeetingParticipantModel> participants;
  const ActionItemsTab({
    super.key,
    required this.meetingId,
    required this.participants,
  });
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController(),
        description = TextEditingController();
    int? assignee = participants.isEmpty ? null : participants.first.userId;
    DateTime? due;
    String? error;
    bool isCreating = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New action item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Action required',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: assignee,
                  decoration: const InputDecoration(labelText: 'Assign to'),
                  items: participants
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.userId,
                          child: Text(p.username),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => assignee = v,
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    due == null ? 'No due date' : 'Due ${_date(due!)}',
                  ),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => due = picked);
                  },
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (title.text.trim().isEmpty || assignee == null) {
                        setState(
                          () => error = 'Enter a title and select an assignee.',
                        );
                        return;
                      }
                      setState(() {
                        isCreating = true;
                        error = null;
                      });
                      try {
                        await ref
                            .read(actionItemProvider(meetingId).notifier)
                            .create(
                              title: title.text.trim(),
                              description: description.text.trim(),
                              assigneeUserId: assignee!,
                              dueDate: due,
                            );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          setState(() {
                            isCreating = false;
                            error = 'Could not create action item: $e';
                          });
                        }
                      }
                    },
              child: isCreating
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Creating...'),
                      ],
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _status(
    BuildContext context,
    WidgetRef ref,
    int id,
    String current,
  ) async {
    String value = current;
    final note = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: value,
                items: const [
                  DropdownMenuItem(value: 'OPEN', child: Text('Open')),
                  DropdownMenuItem(
                    value: 'IN_PROGRESS',
                    child: Text('In progress'),
                  ),
                  DropdownMenuItem(
                    value: 'COMPLETED',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'CANCELLED',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (v) => setState(() => value = v!),
              ),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Progress/completion note',
                ),
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
                    .read(actionItemProvider(meetingId).notifier)
                    .status(id, value, note.text.trim());
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(actionItemProvider(meetingId));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: participants.isEmpty ? null : () => _add(context, ref),
        icon: const Icon(Icons.add_task),
        label: const Text('Add action'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(actionItemProvider(meetingId).notifier).load(),
        child: items.when(
          loading: () => const AppLoading(),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load action items: $e'),
              ),
            ],
          ),
          data: (list) => list.isEmpty
              ? const AppEmptyState(message: 'No action items for this meeting')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index],
                        overdue =
                            item.dueDate != null &&
                            item.dueDate!.isBefore(DateTime.now()) &&
                            item.status != 'COMPLETED';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _icon(item.status),
                          color: overdue ? Colors.red : _color(item.status),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.assigneeUsername}${item.dueDate == null ? '' : ' · Due ${_date(item.dueDate!)}'}\n${item.description ?? ''}${item.completionNote == null ? '' : '\n${item.completionNote}'}',
                        ),
                        isThreeLine: true,
                        trailing: item.editableByCurrentUser
                            ? IconButton(
                                tooltip: 'Update status',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _status(context, ref, item.id, item.status),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static IconData _icon(String s) => s == 'COMPLETED'
      ? Icons.task_alt
      : s == 'IN_PROGRESS'
      ? Icons.timelapse
      : Icons.radio_button_unchecked;
  static Color _color(String s) => s == 'COMPLETED'
      ? Colors.green
      : s == 'IN_PROGRESS'
      ? Colors.orange
      : Colors.indigo;
}
