import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/comment_request.dart';
import '../model/comment_model.dart';
import '../../meetings/provider/meeting_provider.dart';
import '../model/share_comment_request.dart';
import '../model/share_paper_request.dart';
import '../provider/comment_provider.dart';
import 'comment_card.dart';

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

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref, [CommentModel? existing]) async {
    final textController = TextEditingController(text: existing?.commentText ?? '');
    final pageController = TextEditingController(text: existing?.pageNumber?.toString() ?? '');
    bool annotated = existing?.annotated ?? false;
    String visibility = existing?.visibility ?? 'ALL_PARTICIPANTS';
    final selectedIds = <int>{...?existing?.selectedUserIds};
    final participants = meetingId == null
        ? const <dynamic>[]
        : ref.read(participantListProvider(meetingId!)).value ?? const [];
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(existing == null ? 'Add Comment' : 'Edit Comment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                TextField(
                  controller: pageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Page number (optional)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: const InputDecoration(labelText: 'Visibility'),
                  items: const [
                    DropdownMenuItem(value: 'PRIVATE', child: Text('Private — only me')),
                    DropdownMenuItem(value: 'SELECTED_PARTICIPANTS', child: Text('Selected participants')),
                    DropdownMenuItem(value: 'ALL_PARTICIPANTS', child: Text('All participants')),
                  ],
                  onChanged: (value) => setLocalState(() => visibility = value!),
                ),
                if (visibility == 'SELECTED_PARTICIPANTS') ...[
                  const SizedBox(height: 8),
                  if (participants.isEmpty)
                    const Text('Open this paper from a meeting to select participants.')
                  else
                    ...participants.map((participant) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(participant.username),
                      value: selectedIds.contains(participant.userId),
                      onChanged: (checked) => setLocalState(() => checked == true
                          ? selectedIds.add(participant.userId)
                          : selectedIds.remove(participant.userId)),
                    )),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
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
                final text = textController.text.trim();

                if (text.isEmpty) {
                  setLocalState(() {
                    errorMessage = 'Please enter a comment.';
                  });
                  return;
                }
                if (visibility == 'SELECTED_PARTICIPANTS' && selectedIds.isEmpty) {
                  setLocalState(() => errorMessage = 'Select at least one participant.');
                  return;
                }

                final request = CommentRequest(
                  meetingId: meetingId,
                  paperId: paperId,
                  commentText: text,
                  annotated: annotated,
                  visibility: visibility,
                  pageNumber: int.tryParse(pageController.text.trim()),
                  selectedUserIds: selectedIds.toList(),
                );

                if (paperId != null) {
                  final notifier = ref.read(paperCommentProvider(paperId!).notifier);
                  existing == null ? await notifier.addComment(request) : await notifier.updateComment(existing.id, request);
                } else if (meetingId != null) {
                  final notifier = ref.read(meetingCommentProvider(meetingId!).notifier);
                  existing == null ? await notifier.addComment(request) : await notifier.updateComment(existing.id, request);
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (paperId != null) {
                await ref
                    .read(paperCommentProvider(paperId!).notifier)
                    .shareComment(
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

  Future<void> _showSharePaperDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(paperCommentProvider(paperId!).notifier)
                  .sharePaper(
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

  Future<void> _deleteComment(BuildContext context, WidgetRef ref, CommentModel comment) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Delete comment?'),
      content: const Text('This also removes its replies and reactions.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
      ],
    ));
    if (confirmed != true) return;
    if (paperId != null) {
      await ref.read(paperCommentProvider(paperId!).notifier).deleteComment(comment.id);
    } else {
      await ref.read(meetingCommentProvider(meetingId!).notifier).deleteComment(comment.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile);
    final asyncComments = paperId != null
        ? ref.watch(paperCommentProvider(paperId!))
        : ref.watch(meetingCommentProvider(meetingId!));

    if (!access.canCommentPapers) {
      return const Scaffold(
        body: Center(child: Text('You do not have access to paper comments.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Comments - $title'),
        actions: [
          if (paperId != null && access.canCommentPapers)
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
              return CommentCard(
                comment: comment,
                onReply: (message) => paperId != null
                    ? ref
                          .read(paperCommentProvider(paperId!).notifier)
                          .reply(comment.id, message)
                    : ref
                          .read(meetingCommentProvider(meetingId!).notifier)
                          .reply(comment.id, message),
                onReact: paperId != null
                    ? (reaction) => ref
                          .read(paperCommentProvider(paperId!).notifier)
                          .react(comment.id, reaction)
                    : null,
                onShare: paperId != null
                    ? () => _showShareCommentDialog(context, ref, comment.id)
                    : null,
                onEdit: comment.ownedByCurrentUser ? () => _showAddDialog(context, ref, comment) : null,
                onDelete: comment.ownedByCurrentUser ? () => _deleteComment(context, ref, comment) : null,
              );
            },
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load comments: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
