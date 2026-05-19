import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/attachment_request.dart';
import '../provider/paper_provider.dart';

class AttachmentScreen extends ConsumerWidget {
  final int paperId;
  final String paperTitle;

  const AttachmentScreen({
    super.key,
    required this.paperId,
    required this.paperTitle,
  });

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final fileNameController = TextEditingController();
    final filePathController = TextEditingController();
    final orderController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Attachment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fileNameController,
              decoration: const InputDecoration(labelText: 'File Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: filePathController,
              decoration: const InputDecoration(labelText: 'File Path'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orderController,
              decoration: const InputDecoration(labelText: 'Display Order'),
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
                  .read(attachmentListProvider(paperId).notifier)
                  .addAttachment(
                    AttachmentRequest(
                      paperId: paperId,
                      fileName: fileNameController.text.trim(),
                      filePath: filePathController.text.trim(),
                      displayOrder: orderController.text.trim().isEmpty
                          ? null
                          : int.parse(orderController.text.trim()),
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(attachmentListProvider(paperId));
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');

    if (!access.canViewPapers) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have access to board papers.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Attachments - $paperTitle')),
      floatingActionButton: access.canUploadPapers
          ? FloatingActionButton(
              onPressed: () => _showAddDialog(context, ref),
              child: const Icon(Icons.attach_file),
            )
          : null,
      body: attachmentsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No attachments found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final attachment = items[index];
              return Card(
                child: ListTile(
                  title: Text(attachment.fileName),
                  subtitle: Text(attachment.filePath),
                ),
              );
            },
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load attachments: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
