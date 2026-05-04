import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(agendaSectionProvider(meetingId));

    return Scaffold(
      appBar: AppBar(title: Text('Agenda Sections - $meetingTitle')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
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
