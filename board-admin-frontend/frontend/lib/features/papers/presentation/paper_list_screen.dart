import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/paper_provider.dart';
import 'attachment_screen.dart';
import 'paper_form_screen.dart';

class PaperListScreen extends ConsumerWidget {
  final int meetingId;
  final String meetingTitle;

  const PaperListScreen({
    super.key,
    required this.meetingId,
    required this.meetingTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(paperListProvider(meetingId));

    return Scaffold(
      appBar: AppBar(title: Text('Papers - $meetingTitle')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaperFormScreen(meetingId: meetingId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: papersAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No papers found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final paper = items[index];
              return Card(
                child: ListTile(
                  title: Text(paper.title),
                  subtitle: Text(
                    '${paper.paperType} • Ref: ${paper.referenceNumber ?? '-'}\n'
                    'Approval: ${paper.requiresApproval ? 'Required' : 'No'}',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttachmentScreen(
                          paperId: paper.id,
                          paperTitle: paper.title,
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
            Center(child: Text('Failed to load papers: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
