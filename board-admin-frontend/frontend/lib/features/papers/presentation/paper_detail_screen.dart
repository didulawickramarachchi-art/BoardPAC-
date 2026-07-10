import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../../comments/model/comment_request.dart';
import '../../comments/provider/comment_provider.dart';
import '../model/attachment_model.dart';
import '../model/paper_model.dart';
import '../provider/paper_provider.dart';
import 'attachment_screen.dart';

class PaperDetailScreen extends ConsumerWidget {
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
      appBar: AppBar(
        title: Text(paper.title),
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
                      (comment) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.comment_outlined),
                          title: Text(comment.createdByUsername),
                          subtitle: Text(comment.commentText),
                          trailing: comment.annotated
                              ? const Icon(Icons.draw_outlined)
                              : null,
                        ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paper.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(paper.paperType)),
                Chip(label: Text('Version ${paper.versionNumber ?? 1}')),
                if (paper.referenceNumber?.trim().isNotEmpty == true)
                  Chip(label: Text('Ref ${paper.referenceNumber}')),
                Chip(
                  label: Text(
                    paper.requiresApproval ? 'Approval required' : 'No approval needed',
                  ),
                ),
              ],
            ),
            if (hasFile) ...[
              const SizedBox(height: 12),
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

  const _AttachmentCard({
    required this.attachment,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _FilePreview(
          fileName: attachment.fileName,
          filePath: attachment.filePath,
          onOpen: onOpen,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
              color: const Color(0xFFE9ECF3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.picture_as_pdf_outlined, size: 44),
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open'),
            ),
          ],
        ),
      ],
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
  final Widget? action;

  const _SectionHeader({
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
