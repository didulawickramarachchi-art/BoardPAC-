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

  Future<void> showAddDialog(
    BuildContext context,
    WidgetRef ref, [
    CommentModel? existing,
  ]) async {
    final textController = TextEditingController(
      text: existing?.commentText ?? '',
    );
    final pageController = TextEditingController(
      text: existing?.pageNumber?.toString() ?? '',
    );
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
                  decoration: const InputDecoration(
                    labelText: 'Page number (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: const InputDecoration(labelText: 'Visibility'),
                  items: const [
                    DropdownMenuItem(
                      value: 'PRIVATE',
                      child: Text('Private — only me'),
                    ),
                    DropdownMenuItem(
                      value: 'SELECTED_PARTICIPANTS',
                      child: Text('Selected participants'),
                    ),
                    DropdownMenuItem(
                      value: 'ALL_PARTICIPANTS',
                      child: Text('All participants'),
                    ),
                  ],
                  onChanged: (value) =>
                      setLocalState(() => visibility = value!),
                ),
                if (visibility == 'SELECTED_PARTICIPANTS') ...[
                  const SizedBox(height: 8),
                  if (participants.isEmpty)
                    const Text(
                      'Open this paper from a meeting to select participants.',
                    )
                  else
                    ...participants.map(
                      (participant) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(participant.username),
                        value: selectedIds.contains(participant.userId),
                        onChanged: (checked) => setLocalState(
                          () => checked == true
                              ? selectedIds.add(participant.userId)
                              : selectedIds.remove(participant.userId),
                        ),
                      ),
                    ),
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
                if (visibility == 'SELECTED_PARTICIPANTS' &&
                    selectedIds.isEmpty) {
                  setLocalState(
                    () => errorMessage = 'Select at least one participant.',
                  );
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
                  final notifier = ref.read(
                    paperCommentProvider(paperId!).notifier,
                  );
                  existing == null
                      ? await notifier.addComment(request)
                      : await notifier.updateComment(existing.id, request);
                } else if (meetingId != null) {
                  final notifier = ref.read(
                    meetingCommentProvider(meetingId!).notifier,
                  );
                  existing == null
                      ? await notifier.addComment(request)
                      : await notifier.updateComment(existing.id, request);
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

  Future<void> _deleteComment(
    BuildContext context,
    WidgetRef ref,
    CommentModel comment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This also removes its replies and reactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (paperId != null) {
      await ref
          .read(paperCommentProvider(paperId!).notifier)
          .deleteComment(comment.id);
    } else {
      await ref
          .read(meetingCommentProvider(meetingId!).notifier)
          .deleteComment(comment.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composerKey = GlobalKey<_CommentComposerState>();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comments',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          if (paperId != null && access.canCommentPapers)
            IconButton(
              onPressed: () => _showSharePaperDialog(context, ref),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      bottomNavigationBar: _CommentComposer(
        key: composerKey,
        paperId: paperId,
        meetingId: meetingId,
      ),
      body: asyncComments.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No comments found');
          }

          return RefreshIndicator(
            onRefresh: () => paperId != null
                ? ref.read(paperCommentProvider(paperId!).notifier).load()
                : ref.read(meetingCommentProvider(meetingId!).notifier).load(),
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
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
                  onEdit: comment.ownedByCurrentUser
                      ? () => composerKey.currentState?.edit(comment)
                      : null,
                  onDelete: comment.ownedByCurrentUser
                      ? () => _deleteComment(context, ref, comment)
                      : null,
                );
              },
            ),
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load comments: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}

class _CommentComposer extends ConsumerStatefulWidget {
  final int? paperId;
  final int? meetingId;
  const _CommentComposer({super.key, this.paperId, this.meetingId});

  @override
  ConsumerState<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<_CommentComposer> {
  final _controller = TextEditingController();
  final _pageController = TextEditingController();
  final _focusNode = FocusNode();
  bool _annotated = false;
  bool _showSettings = false;
  bool _sending = false;
  String _visibility = 'ALL_PARTICIPANTS';
  final Set<int> _selectedIds = {};
  CommentModel? _editing;

  void edit(CommentModel comment) {
    setState(() {
      _editing = comment;
      _controller.text = comment.commentText;
      _pageController.text = comment.pageNumber?.toString() ?? '';
      _annotated = comment.annotated;
      _visibility = comment.visibility;
      _selectedIds
        ..clear()
        ..addAll(comment.selectedUserIds);
      _showSettings = true;
    });
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    _controller.clear();
    _pageController.clear();
    setState(() {
      _editing = null;
      _annotated = false;
      _visibility = 'ALL_PARTICIPANTS';
      _selectedIds.clear();
      _showSettings = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final request = CommentRequest(
        paperId: widget.paperId,
        meetingId: widget.meetingId,
        commentText: message,
        annotated: _annotated,
        visibility: _visibility,
        pageNumber: int.tryParse(_pageController.text.trim()),
        selectedUserIds: _selectedIds.toList(),
      );
      if (widget.paperId != null) {
        final notifier = ref.read(
          paperCommentProvider(widget.paperId!).notifier,
        );
        _editing == null
            ? await notifier.addComment(request)
            : await notifier.updateComment(_editing!.id, request);
      } else if (widget.meetingId != null) {
        final notifier = ref.read(
          meetingCommentProvider(widget.meetingId!).notifier,
        );
        _editing == null
            ? await notifier.addComment(request)
            : await notifier.updateComment(_editing!.id, request);
      }
      _controller.clear();
      _pageController.clear();
      if (mounted) {
        setState(() {
          _editing = null;
          _annotated = false;
          _visibility = 'ALL_PARTICIPANTS';
          _selectedIds.clear();
          _showSettings = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add comment: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final participants = widget.meetingId == null
        ? const <dynamic>[]
        : ref.watch(participantListProvider(widget.meetingId!)).value ??
              const [];
    return Material(
      color: Colors.white,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_editing != null)
                Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF1877F2),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing ${_editing!.createdByUsername}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: _cancelEdit,
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel edit',
                    ),
                  ],
                ),
              if (_showSettings) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_visibility),
                        initialValue: _visibility,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Visibility',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PRIVATE',
                            child: Text('Private'),
                          ),
                          DropdownMenuItem(
                            value: 'SELECTED_PARTICIPANTS',
                            child: Text('Selected people'),
                          ),
                          DropdownMenuItem(
                            value: 'ALL_PARTICIPANTS',
                            child: Text('All participants'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _visibility = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 105,
                      child: TextField(
                        controller: _pageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Page'),
                      ),
                    ),
                  ],
                ),
                if (_visibility == 'SELECTED_PARTICIPANTS')
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 110),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        children: participants
                            .map<Widget>(
                              (participant) => FilterChip(
                                label: Text(participant.username),
                                selected: _selectedIds.contains(
                                  participant.userId,
                                ),
                                onSelected: (selected) => setState(
                                  () => selected
                                      ? _selectedIds.add(participant.userId)
                                      : _selectedIds.remove(participant.userId),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFDCE5FA),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF12275B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        filled: true,
                        fillColor: const Color(0xFFF0F2F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          tooltip: 'Comment settings',
                          onPressed: () =>
                              setState(() => _showSettings = !_showSettings),
                          icon: Icon(
                            Icons.tune,
                            color: _showSettings
                                ? const Color(0xFF1877F2)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: 'Send comment',
                    onPressed: _sending ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                    ),
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
              if (_showSettings)
                CheckboxListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 44),
                  value: _annotated,
                  onChanged: (value) =>
                      setState(() => _annotated = value ?? false),
                  title: const Text('Annotated'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
