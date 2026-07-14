import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/reaction_bar.dart';
import '../../auth/provider/auth_provider.dart';
import '../../comments/model/comment_request.dart';
import '../../comments/provider/comment_provider.dart';
import '../../comments/presentation/comment_card.dart';
import '../model/attachment_model.dart';
import '../model/paper_model.dart';
import '../provider/paper_provider.dart';
import 'attachment_screen.dart';

class PaperDetailScreen extends ConsumerWidget {
  static const Color primaryBlue = Color(0xFF12275B);
  static const Color background = Color(0xFFF6F7FB);

  final PaperModel paper;

  const PaperDetailScreen({
    super.key,
    required this.paper,
  });

  Future<void> _openFile(BuildContext context, String? url) async {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file is available to open.')),
      );
      return;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open this file path: $value')),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file.')),
      );
    }
  }

  Future<void> _showAddCommentDialog(BuildContext context, WidgetRef ref) async {
    final textController = TextEditingController();
    bool annotated = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Comment'),
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
                    setState(() => annotated = value ?? false);
                  },
                  title: const Text('Annotated'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final auth = ref.read(authProvider);
                final userId = auth.userId;
                final text = textController.text.trim();

                if (userId == null) {
                  setState(() {
                    errorMessage = 'Please log in again before commenting.';
                  });
                  return;
                }

                if (text.isEmpty) {
                  setState(() {
                    errorMessage = 'Please enter a comment.';
                  });
                  return;
                }

                await ref.read(paperCommentProvider(paper.id).notifier).addComment(
                      CommentRequest(
                        paperId: paper.id,
                        createdByUserId: userId,
                        commentText: text,
                        annotated: annotated,
                      ),
                    );

                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER');
    final attachmentsAsync = ref.watch(attachmentListProvider(paper.id));
    final commentsAsync = ref.watch(paperCommentProvider(paper.id));

    if (!access.canViewPapers) {
      return const Scaffold(
        body: Center(child: Text('You do not have access to board papers.')),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Paper Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(attachmentListProvider(paper.id));
              ref.invalidate(paperCommentProvider(paper.id));
            },
          ),
        ],
      ),
      floatingActionButton: access.canCommentPapers
          ? FloatingActionButton.extended(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Comment'),
              onPressed: () => _showAddCommentDialog(context, ref),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PaperHeaderCard(
            paper: paper,
            onOpen: () => _openFile(context, paper.filePath),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Attachments',
            icon: Icons.attach_file_rounded,
            action: access.canUploadPapers
                ? TextButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Manage'),
                    onPressed: () {
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
                  )
                : null,
          ),
          attachmentsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const AppEmptyState(message: 'No attachments found');
              }

              return Column(
                children: items
                    .map(
                      (attachment) => _AttachmentCard(
                        attachment: attachment,
                        onOpen: () => _openFile(context, attachment.filePath),
                        onReact: (reaction) => ref
                            .read(attachmentListProvider(paper.id).notifier)
                            .react(attachment.id, reaction),
                      ),
                    )
                    .toList(),
              );
            },
            error: (error, _) => Text('Failed to load attachments: $error'),
            loading: () => const AppLoading(),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Comments',
            icon: Icons.forum_outlined,
            action: access.canCommentPapers
                ? TextButton.icon(
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('Add'),
                    onPressed: () => _showAddCommentDialog(context, ref),
                  )
                : null,
          ),
          commentsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const AppEmptyState(message: 'No comments found');
              }

              return Column(
                children: items
                    .map(
                      (comment) => CommentCard(
                        comment: comment,
                        onReact: (reaction) => ref
                            .read(paperCommentProvider(paper.id).notifier)
                            .react(comment.id, reaction),
                      ),
                    )
                    .toList(),
              );
            },
            error: (error, _) => Text('Failed to load comments: $error'),
            loading: () => const AppLoading(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _PaperHeaderCard extends StatelessWidget {
  final PaperModel paper;
  final VoidCallback onOpen;

  const _PaperHeaderCard({
    required this.paper,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = paper.filePath?.trim().isNotEmpty == true;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12275B), Color(0xFF233E8B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2612275B),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFFFFB52E),
                size: 25,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              paper.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: paper.paperType),
                _InfoChip(label: 'Version ${paper.versionNumber ?? 1}'),
                if (paper.referenceNumber?.trim().isNotEmpty == true)
                  _InfoChip(label: 'Ref ${paper.referenceNumber}'),
                _InfoChip(
                  label: paper.requiresApproval
                      ? 'Approval required'
                      : 'No approval needed',
                  highlighted: paper.requiresApproval,
                ),
              ],
            ),
            if (hasFile) ...[
              const SizedBox(height: 18),
              _FilePreview(
                fileName: paper.fileName ?? paper.title,
                filePath: paper.filePath!,
                onOpen: onOpen,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final AttachmentModel attachment;
  final VoidCallback onOpen;
  final ValueChanged<String> onReact;

  const _AttachmentCard({
    required this.attachment,
    required this.onOpen,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE8EBF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _FilePreview(
              fileName: attachment.fileName,
              filePath: attachment.filePath,
              onOpen: onOpen,
            ),
            const Divider(height: 20),
            ReactionBar(
              currentReaction: attachment.currentReaction,
              counts: attachment.reactionCounts,
              onReact: onReact,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  final String fileName;
  final String filePath;
  final VoidCallback onOpen;

  const _FilePreview({
    required this.fileName,
    required this.filePath,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = _isImage(fileName) || _isImage(filePath);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  filePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFE9ECF3),
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 46,
                  color: Color(0xFFE74C3C),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF00184A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _isImage(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? action;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF233E8B).withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF233E8B), size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF00184A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _InfoChip({required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFFFB52E)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: highlighted
            ? null
            : Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? const Color(0xFF00184A) : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
