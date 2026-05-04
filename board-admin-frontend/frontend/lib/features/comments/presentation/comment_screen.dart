import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/comment_request.dart';
import '../model/share_comment_request.dart';
import '../model/share_paper_request.dart';
import '../provider/comment_provider.dart';

class CommentScreen extends ConsumerWidget {
  final int? paperId;
  final int? meetingId;
  final String title;

  const CommentScreen({
    super.key,
    this.paperId,
    this.meetingId,
    required this.title,
  });

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final userIdController = TextEditingController(text: '1');
    final textController = TextEditingController();
    bool annotated = false;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Add Comment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userIdController,
                  decoration: const InputDecoration(labelText: 'User ID'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(labelText: 'Comment'),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: annotated,
                  onChanged: (value) {
                    setLocalState(() => annotated = value ?? false);
                  },
                  title: const Text('Annotated'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
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
                final request = CommentRequest(
                  meetingId: meetingId,
                  paperId: paperId,
                  createdByUserId: int.parse(userIdController.text.trim()),
                  commentText: textController.text.trim(),
                  annotated: annotated,
                );

                if (paperId != null) {
                  await ref.read(paperCommentProvider(paperId!).notifier).addComment(request);
                } else if (meetingId != null) {
                  await ref.read(meetingCommentProvider(meetingId!).notifier).addComment(request);
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showShareCommentDialog(
    BuildContext context,
    WidgetRef ref,
    int commentId,
  ) async {
    final fromController = TextEditingController(text: '1');
    final toController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromController,
              decoration: const InputDecoration(labelText: 'Shared By User ID'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: toController,
              decoration: const InputDecoration(labelText: 'Shared To User ID'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (paperId != null) {
                await ref.read(paperCommentProvider(paperId!).notifier).shareComment(
                      ShareCommentRequest(
                        commentId: commentId,
                        sharedByUserId: int.parse(fromController.text.trim()),
                        sharedToUserId: int.parse(toController.text.trim()),
                      ),
                    );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSharePaperDialog(BuildContext context, WidgetRef ref) async {
    if (paperId == null) return;

    final fromController = TextEditingController(text: '1');
    final toController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share Paper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromController,
              decoration: const InputDecoration(labelText: 'Shared By User ID'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: toController,
              decoration: const InputDecoration(labelText: 'Shared To User ID'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(paperCommentProvider(paperId!).notifier).sharePaper(
                    SharePaperRequest(
                      paperId: paperId!,
                      sharedByUserId: int.parse(fromController.text.trim()),
                      sharedToUserId: int.parse(toController.text.trim()),
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncComments = paperId != null
        ? ref.watch(paperCommentProvider(paperId!))
        : ref.watch(meetingCommentProvider(meetingId!));

    return Scaffold(
      appBar: AppBar(
        title: Text('Comments - $title'),
        actions: [
          if (paperId != null)
            IconButton(
              onPressed: () => _showSharePaperDialog(context, ref),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add_comment_outlined),
      ),
      body: asyncComments.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No comments found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final comment = items[index];
              return Card(
                child: ListTile(
                  title: Text(comment.createdByUsername),
                  subtitle: Text(
                    '${comment.commentText}\nAnnotated: ${comment.annotated ? 'Yes' : 'No'}',
                  ),
                  isThreeLine: true,
                  trailing: paperId != null
                      ? IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _showShareCommentDialog(context, ref, comment.id),
                        )
                      : null,
                ),
              );
            },
          );
        },
        error: (error, _) => Center(child: Text('Failed to load comments: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}