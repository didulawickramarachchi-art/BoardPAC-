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
      appBar: AppBar(
        title: Text('Papers - $meetingTitle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(paperListProvider(meetingId));
            },
          )
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Paper'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaperFormScreen(meetingId: meetingId),
            ),
          );

          // 🔥 refresh after adding
          ref.refresh(paperListProvider(meetingId));
        },
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
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),

                  title: Text(
                    paper.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),

                      // Paper Type + Ref
                      Text(
                        '${paper.paperType} • Ref: ${paper.referenceNumber ?? '-'}',
                      ),

                      const SizedBox(height: 4),

                      // Approval Status
                      Row(
                        children: [
                          Icon(
                            paper.requiresApproval
                                ? Icons.verified
                                : Icons.check_circle,
                            size: 16,
                            color: paper.requiresApproval
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            paper.requiresApproval
                                ? 'Approval Required'
                                : 'No Approval Needed',
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Version
                      Text('Version: ${paper.versionNumber ?? 1}'),
                    ],
                  ),

                  isThreeLine: true,

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'open') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttachmentScreen(
                              paperId: paper.id,
                              paperTitle: paper.title,
                            ),
                          ),
                        );
                      } else if (value == 'approve') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Approve action')),
                        );
                      } else if (value == 'comment') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment action')),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('Open'),
                      ),
                      if (paper.requiresApproval)
                        const PopupMenuItem(
                          value: 'approve',
                          child: Text('Approve'),
                        ),
                      const PopupMenuItem(
                        value: 'comment',
                        child: Text('Comment'),
                      ),
                    ],
                  ),

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

        error: (error, _) => Center(
          child: Text(
            'Failed to load papers:\n$error',
            textAlign: TextAlign.center,
          ),
        ),

        loading: () => const AppLoading(),
      ),
    );
  }
}