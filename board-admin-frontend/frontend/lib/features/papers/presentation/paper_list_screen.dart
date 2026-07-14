import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/annotations/presentation/annotation_screen.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../../comments/presentation/comment_screen.dart';
import '../provider/paper_provider.dart';
import 'attachment_screen.dart';
import 'paper_detail_screen.dart';
import 'paper_form_screen.dart';

class PaperListScreen extends ConsumerWidget {
  static const Color _primaryBlue = Color(0xFF12275B);
  static const Color _cardBlue = Color(0xFF233E8B);
  static const Color _background = Color(0xFFF6F7FB);

  final int? meetingId;
  final String meetingTitle;

  const PaperListScreen({
    super.key,
    this.meetingId,
    this.meetingTitle = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = meetingId == null
        ? ref.watch(allPaperListProvider)
        : ref.watch(paperListProvider(meetingId!));
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');
    final isSecretary = access.isSecretary;

    if (!access.canViewPapers) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have access to board papers.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(meetingId == null
            ? 'Papers'
            : isSecretary
                ? 'Papers for $meetingTitle (ID: $meetingId)'
                : 'Papers - $meetingTitle'),
        actions: [
          IconButton(
            tooltip: 'Refresh papers',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (meetingId == null) {
                ref.invalidate(allPaperListProvider);
              } else {
                ref.invalidate(paperListProvider(meetingId!));
              }
            },
          ),
        ],
      ),

      floatingActionButton: access.canUploadPapers && meetingId != null
          ? FloatingActionButton.extended(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Paper'),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaperFormScreen(meetingId: meetingId!),
                  ),
                );

                ref.invalidate(paperListProvider(meetingId!));
              },
            )
          : null,

      body: papersAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No papers found');
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final paper = items[index];

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE8EBF2)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),

                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _cardBlue.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: _cardBlue,
                      size: 25,
                    ),
                  ),

                  title: Text(
                    paper.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF00184A),
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        '${paper.paperType} • Ref: ${paper.referenceNumber ?? '-'}',
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _PaperStatusChip(
                            icon: paper.requiresApproval
                                ? Icons.pending_actions_rounded
                                : Icons.check_circle_outline_rounded,
                            label: paper.requiresApproval
                                ? 'Approval required'
                                : 'No approval needed',
                            foreground: paper.requiresApproval
                                ? const Color(0xFF9A5B00)
                                : const Color(0xFF16835B),
                            background: paper.requiresApproval
                                ? const Color(0xFFFFF3DC)
                                : const Color(0xFFE0F8F1),
                          ),
                          _PaperStatusChip(
                            icon: Icons.layers_outlined,
                            label: 'Version ${paper.versionNumber ?? 1}',
                            foreground: _cardBlue,
                            background: const Color(0xFFEAF0FF),
                          ),
                        ],
                      ),
                    ],
                  ),

                  isThreeLine: true,

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'open') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaperDetailScreen(paper: paper),
                          ),
                        );
                      } else if (value == 'attachments') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttachmentScreen(
                              paperId: paper.id,
                              paperTitle: paper.title,
                            ),
                          ),
                        );
                      } else if (value == 'annotations') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnnotationScreen(
                              paperId: paper.id,
                              userId: 1,
                              paperTitle: paper.title,
                            ),
                          ),
                        );
                      } else if (value == 'approve' && access.canUploadPapers) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Approve action')),
                        );
                      } else if (value == 'comment' &&
                          access.canCommentPapers) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentScreen(
                              paperId: paper.id,
                              title: paper.title,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('View Paper'),
                      ),
                      const PopupMenuItem(
                        value: 'attachments',
                        child: Text('Attachments'),
                      ),
                      const PopupMenuItem(
                        value: 'annotations',
                        child: Text('Annotations'),
                      ),
                      if (paper.requiresApproval && access.canUploadPapers)
                        const PopupMenuItem(
                          value: 'approve',
                          child: Text('Approve'),
                        ),
                      if (access.canCommentPapers)
                        const PopupMenuItem(
                          value: 'comment',
                          child: Text('Comments'),
                        ),
                    ],
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaperDetailScreen(paper: paper),
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

class _PaperStatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  const _PaperStatusChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
