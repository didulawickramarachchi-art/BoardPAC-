import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../../comments/presentation/comment_screen.dart';
import '../../approvals/presentation/approval_screen.dart';
import '../provider/paper_provider.dart';
import 'attachment_screen.dart';
import 'paper_detail_screen.dart';
import 'paper_form_screen.dart';

class PaperListScreen extends ConsumerWidget {
  static const Color _primaryBlue = Color(0xFF12275B);
  static const Color _cardBlue = Color(0xFF233E8B);

  final int? meetingId;
  final String meetingTitle;

  const PaperListScreen({super.key, this.meetingId, this.meetingTitle = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = meetingId == null
        ? ref.watch(allPaperListProvider)
        : ref.watch(paperListProvider(meetingId!));
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile);
    final isSecretary = access.isSecretary;

    if (!access.canViewPapers) {
      return const Scaffold(
        body: Center(child: Text('You do not have access to board papers.')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          meetingId == null
              ? 'Papers'
              : isSecretary
              ? 'Papers for $meetingTitle (ID: $meetingId)'
              : 'Papers - $meetingTitle',
        ),
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
                color: Theme.of(context).colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),

                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF789CFF).withValues(alpha: 0.16)
                          : _cardBlue.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFAFC4FF)
                          : _cardBlue,
                      size: 25,
                    ),
                  ),

                  title: Text(
                    paper.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
                      } else if (value == 'approve' &&
                          access.canApprovePapers) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApprovalScreen(
                              paperId: paper.id,
                              paperTitle: paper.title,
                            ),
                          ),
                        );
                      } else if (value == 'comment' &&
                          access.canCommentPapers) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentScreen(
                              paperId: paper.id,
                              meetingId: meetingId,
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
                      if (paper.requiresApproval && access.canApprovePapers)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveForeground = isDark
        ? Color.lerp(foreground, Colors.white, 0.38)!
        : foreground;
    final effectiveBackground = isDark
        ? Color.alphaBlend(
            effectiveForeground.withValues(alpha: 0.16),
            Theme.of(context).colorScheme.surfaceContainerHighest,
          )
        : background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: effectiveForeground.withValues(alpha: 0.20))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveForeground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: effectiveForeground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
