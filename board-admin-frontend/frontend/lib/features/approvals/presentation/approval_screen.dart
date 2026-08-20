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
    final userIdController = TextEditingController(text: '1');
    final commentController = TextEditingController();
    String selectedStatus = 'APPROVE';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Submit Approval'),
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
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Approval Status',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
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
                await ref
                    .read(approvalListProvider(paperId).notifier)
                    .submit(
                      ApprovalRequest(
                        paperId: paperId,
                        userId: int.parse(userIdController.text.trim()),
                        approvalStatus: selectedStatus,
                        approvalComment: commentController.text.trim(),
                      ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Submit'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showApprovalDialog(context, ref),
        child: const Icon(Icons.how_to_vote_outlined),
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
                  title: Text(approval.username),
                  subtitle: Text(
                    'Status: ${approval.approvalStatus}\n'
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
}
