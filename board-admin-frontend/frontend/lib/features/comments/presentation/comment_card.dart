import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/comment_model.dart';
import '../../../core/widgets/reaction_bar.dart';
import '../../users/provider/user_provider.dart';

class CommentCard extends StatelessWidget {
  final CommentModel comment;
  final ValueChanged<String>? onReact;
  final VoidCallback? onShare;
  final Future<void> Function(String message)? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    this.onReact,
    this.onShare,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  Future<void> _showReplyDialog(BuildContext context) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reply to ${comment.createdByUsername}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reply',
            hintText: 'Write a reply...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
    if (message != null) await onReply?.call(message);
  }

  @override
  Widget build(BuildContext context) {
    final initial = comment.createdByUsername.trim().isEmpty
        ? '?'
        : comment.createdByUsername.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserAvatar(
            userId: comment.createdByUserId,
            imageUrl: comment.createdByProfilePictureUrl,
            initial: initial,
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comment.createdByUsername,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF12275B),
                              ),
                            ),
                          ),
                          if (comment.annotated)
                            const Icon(
                              Icons.draw_outlined,
                              size: 16,
                              color: Color(0xFF6E7DA5),
                            ),
                          if (onEdit != null || onDelete != null)
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              onSelected: (value) => value == 'edit' ? onEdit?.call() : onDelete?.call(),
                              itemBuilder: (_) => [
                                if (onEdit != null) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                if (onDelete != null) const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                        ],
                      ),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(comment.visibility == 'PRIVATE' ? Icons.lock_outline : comment.visibility == 'SELECTED_PARTICIPANTS' ? Icons.group_outlined : Icons.public, size: 15),
                          label: Text(comment.visibility == 'PRIVATE' ? 'Private' : comment.visibility == 'SELECTED_PARTICIPANTS' ? 'Selected' : 'All participants'),
                        ),
                        if (comment.pageNumber != null) Chip(visualDensity: VisualDensity.compact, label: Text('Page ${comment.pageNumber}')),
                      ]),
                      const SizedBox(height: 4),
                      Text(comment.commentText),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 5),
                  child: Row(
                    children: [
                      if (onReact != null)
                        Expanded(
                          child: ReactionBar(
                            currentReaction: comment.currentReaction,
                            counts: comment.reactionCounts,
                            onReact: onReact!,
                          ),
                        ),
                      if (onShare != null) ...[
                        const SizedBox(width: 18),
                        InkWell(
                          onTap: onShare,
                          child: const Text(
                            'Share',
                            style: TextStyle(
                              color: Color(0xFF5F6673),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (onReply != null) ...[
                        const SizedBox(width: 18),
                        InkWell(
                          onTap: () => _showReplyDialog(context),
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              color: Color(0xFF5F6673),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...comment.replies.map((reply) => _ReplyRow(reply: reply)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyRow extends StatelessWidget {
  final CommentReplyModel reply;
  const _ReplyRow({required this.reply});

  @override
  Widget build(BuildContext context) {
    final initial = reply.createdByUsername.trim().isEmpty
        ? '?'
        : reply.createdByUsername.trim()[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserAvatar(
            userId: reply.createdByUserId,
            imageUrl: reply.createdByProfilePictureUrl,
            initial: initial,
            radius: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reply.createdByUsername,
                    style: const TextStyle(
                      color: Color(0xFF12275B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(reply.message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends ConsumerWidget {
  final int userId;
  final String? imageUrl;
  final String initial;
  final double radius;
  const _UserAvatar({
    required this.userId,
    required this.imageUrl,
    required this.initial,
    required this.radius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = imageUrl?.trim() ?? '';
    final picture = url.isEmpty || userId <= 0
        ? null
        : ref.watch(profilePictureProvider((userId: userId, url: url)));
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFDCE5FA),
      child: ClipOval(
        child: SizedBox.square(
          dimension: radius * 2,
          child:
              picture?.when(
                data: (bytes) => Image.memory(bytes, fit: BoxFit.cover),
                loading: () => const Center(
                  child: SizedBox.square(
                    dimension: 13,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                error: (_, _) => _AvatarInitial(initial: initial),
              ) ??
              _AvatarInitial(initial: initial),
        ),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  final String initial;
  const _AvatarInitial({required this.initial});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFDCE5FA),
    child: Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF12275B),
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
