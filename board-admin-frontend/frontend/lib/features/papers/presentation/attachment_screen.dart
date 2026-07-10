import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _openFile(BuildContext context, String filePath) async {
    final uri = Uri.tryParse(filePath.trim());
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open this file path: $filePath')),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the attachment.')),
      );
    }
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final fileNameController = TextEditingController();
    final orderController = TextEditingController();
    PlatformFile? selectedFile;
    Uint8List? selectedBytes;
    String? selectedFilePath;
    bool isUploading = false;
    double uploadProgress = 0;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Attachment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fileNameController,
                  decoration: const InputDecoration(labelText: 'File Name'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'pdf',
                              'png',
                              'jpg',
                              'jpeg',
                              'gif',
                              'webp',
                            ],
                            allowMultiple: false,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            selectedFile = file;
                            selectedBytes = file.bytes;
                            selectedFilePath = file.path;
                            errorMessage = null;
                            uploadProgress = 0;
                            if (fileNameController.text.trim().isEmpty) {
                              fileNameController.text = file.name;
                            }
                            setState(() {});
                          }
                        },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose PDF or Image'),
                ),
                if (selectedFile != null) ...[
                  const SizedBox(height: 12),
                  Text('Selected file: ${selectedFile!.name}'),
                  if ((selectedFile!.name.toLowerCase().endsWith('.png') ||
                          selectedFile!.name.toLowerCase().endsWith('.jpg') ||
                          selectedFile!.name.toLowerCase().endsWith('.jpeg') ||
                          selectedFile!.name.toLowerCase().endsWith('.gif') ||
                          selectedFile!.name.toLowerCase().endsWith('.webp')) &&
                      (selectedBytes != null ||
                          (!kIsWeb && selectedFilePath != null)))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 120,
                        child: selectedBytes != null
                            ? Image.memory(
                                selectedBytes!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(selectedFilePath!),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(labelText: 'Display Order'),
                  keyboardType: TextInputType.number,
                ),
                if (isUploading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: uploadProgress == 0 ? null : uploadProgress),
                  const SizedBox(height: 8),
                  Text(
                    uploadProgress > 0
                        ? '${(uploadProgress * 100).toStringAsFixed(0)}% uploaded'
                        : 'Uploading...',
                  ),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
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
              onPressed: isUploading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      final fileName = fileNameController.text.trim();
                      if (fileName.isEmpty) {
                        setState(() {
                          errorMessage = 'Please enter a file name.';
                        });
                        return;
                      }
                      if (selectedFile == null) {
                        setState(() {
                          errorMessage = 'Please choose a file first.';
                        });
                        return;
                      }

                      final extension = selectedFile!.name.split('.').last.toLowerCase();
                      final allowedTypes = <String>{
                        'pdf',
                        'png',
                        'jpg',
                        'jpeg',
                        'gif',
                        'webp',
                      };
                      if (!allowedTypes.contains(extension)) {
                        setState(() {
                          errorMessage = 'Unsupported file type.';
                        });
                        return;
                      }

                      if ((selectedFile!.size ?? 0) > 10 * 1024 * 1024) {
                        setState(() {
                          errorMessage = 'File size must be 10 MB or less.';
                        });
                        return;
                      }

                      setState(() {
                        isUploading = true;
                        errorMessage = null;
                        uploadProgress = 0;
                      });

                      try {
                        final repository = ref.read(paperRepositoryProvider);
                        final uploadedFilePath = await repository.uploadAttachment(
                          fileName: fileName,
                          filePath: selectedFilePath,
                          fileBytes: selectedBytes,
                          onProgress: (sent, total) {
                            if (total > 0) {
                              setState(() {
                                uploadProgress = sent / total;
                              });
                            }
                          },
                        );

                        await ref
                            .read(attachmentListProvider(paperId).notifier)
                            .addAttachment(
                              AttachmentRequest(
                                paperId: paperId,
                                fileName: fileName,
                                filePath: uploadedFilePath,
                                displayOrder: orderController.text.trim().isEmpty
                                    ? null
                                    : int.parse(orderController.text.trim()),
                              ),
                            );

                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Attachment uploaded successfully.')),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isUploading = false;
                          errorMessage = e.toString();
                        });
                      }
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
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(attachment.fileName),
                  subtitle: Text(
                    attachment.filePath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Open',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openFile(context, attachment.filePath),
                  ),
                  onTap: () => _openFile(context, attachment.filePath),
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
