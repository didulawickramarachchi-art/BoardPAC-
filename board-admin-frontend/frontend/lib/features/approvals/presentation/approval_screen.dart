import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/approval_request.dart';
import '../provider/approval_provider.dart';

class ApprovalScreen extends ConsumerWidget {
  final int paperId;
  final String paperTitle;

  const ApprovalScreen({
    super.key,
    required this.paperId,
    required this.paperTitle,
  });

  Future<void> _showApprovalDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(approvalListProvider(paperId)).value
        ?.where((item) => item.ownedByCurrentUser).firstOrNull;
    final commentController = TextEditingController(text: current?.approvalComment ?? '');
    String selectedStatus = current?.approvalStatus ?? 'APPROVE';
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Submit Approval'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Approval Status',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'APPROVE', child: Text('Approve')),
                    DropdownMenuItem(value: 'REJECT', child: Text('Reject')),
                    DropdownMenuItem(value: 'ABSTAIN', child: Text('Abstain')),
                    DropdownMenuItem(
                      value: 'INTEREST',
                      child: Text('Interest'),
                    ),
                    DropdownMenuItem(value: 'RPT', child: Text('RPT')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Approval Comment',
                  ),
                  maxLines: 3,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
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
                final confirmed = await showDialog<bool>(context: context, builder: (confirmContext) => AlertDialog(
                  title: const Text('Confirm decision'),
                  content: Text('Record “${_statusLabel(selectedStatus)}” for this paper?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(confirmContext, false), child: const Text('Back')),
                    FilledButton(onPressed: () => Navigator.pop(confirmContext, true), child: const Text('Confirm')),
                  ],
                ));
                if (confirmed != true) return;
                try {
                  await ref.read(approvalListProvider(paperId).notifier).submit(ApprovalRequest(
                    paperId: paperId, approvalStatus: selectedStatus,
                    approvalComment: commentController.text.trim(),
                  ));
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  setLocalState(() => errorMessage = 'Could not record decision: $error');
                }
              },
              child: Text(current == null ? 'Submit' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(approvalListProvider(paperId));

    return Scaffold(
      appBar: AppBar(title: Text('Approvals - $paperTitle')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApprovalDialog(context, ref),
        icon: const Icon(Icons.how_to_vote_outlined),
        label: const Text('Record decision'),
      ),
      body: approvalsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No approvals found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final approval = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(approval.approvalStatus).withValues(alpha: .14),
                    child: Icon(_statusIcon(approval.approvalStatus), color: _statusColor(approval.approvalStatus)),
                  ),
                  title: Text(approval.username),
                  subtitle: Text(
                    '${_statusLabel(approval.approvalStatus)}${approval.ownedByCurrentUser ? ' · Your decision' : ''}\n'
                    '${approval.approvalComment ?? ''}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load approvals: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }

  static String _statusLabel(String value) => switch (value) {
    'APPROVE' => 'Approved', 'REJECT' => 'Rejected', 'ABSTAIN' => 'Abstained',
    'INTEREST' => 'Interest declared', 'RPT' => 'Related-party transaction', _ => value,
  };
  static IconData _statusIcon(String value) => switch (value) {
    'APPROVE' => Icons.check_circle_outline, 'REJECT' => Icons.cancel_outlined,
    'ABSTAIN' => Icons.remove_circle_outline, 'INTEREST' => Icons.info_outline,
    _ => Icons.gavel_outlined,
  };
  static Color _statusColor(String value) => switch (value) {
    'APPROVE' => Colors.green, 'REJECT' => Colors.red, 'ABSTAIN' => Colors.orange,
    _ => Colors.indigo,
  };
}
