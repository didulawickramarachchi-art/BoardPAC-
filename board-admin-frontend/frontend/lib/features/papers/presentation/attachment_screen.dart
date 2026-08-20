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

InputDecoration _attachmentInputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF7D8CB2), size: 20),
    filled: true,
    fillColor: const Color(0xFFF6F7FB),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE3E6EE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF233E8B), width: 1.5),
    ),
  );
}

class AttachmentScreen extends ConsumerWidget {
  static const Color _primaryBlue = Color(0xFF12275B);
  static const Color _cardBlue = Color(0xFF233E8B);
  static const Color _gold = Color(0xFFFFB52E);
  static const Color _background = Color(0xFFF6F7FB);

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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(
                    Icons.attach_file_rounded,
                    color: AttachmentScreen._cardBlue,
                    size: 21,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add Attachment',
                  style: TextStyle(
                    color: Color(0xFF00184A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fileNameController,
                  decoration: _attachmentInputDecoration(
                    label: 'File Name',
                    icon: Icons.drive_file_rename_outline_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AttachmentScreen._cardBlue,
                      side: const BorderSide(color: Color(0xFFB8C3E0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text(
                      'Choose PDF or Image',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
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
                            ? Image.memory(selectedBytes!, fit: BoxFit.cover)
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
                  decoration: _attachmentInputDecoration(
                    label: 'Display Order',
                    icon: Icons.format_list_numbered_rounded,
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (isUploading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: uploadProgress == 0 ? null : uploadProgress,
                  ),
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
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF667394),
              ),
              onPressed: isUploading
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AttachmentScreen._primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
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

                      final extension = selectedFile!.name
                          .split('.')
                          .last
                          .toLowerCase();
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

                      if (selectedFile!.size > 10 * 1024 * 1024) {
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
                        final uploadedFilePath = await repository
                            .uploadAttachment(
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
                                displayOrder:
                                    orderController.text.trim().isEmpty
                                    ? null
                                    : int.parse(orderController.text.trim()),
                              ),
                            );

                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Attachment uploaded successfully.',
                              ),
                            ),
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
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile);

    if (!access.canViewPapers) {
      return const Scaffold(
        body: Center(child: Text('You do not have access to board papers.')),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Attachments',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh attachments',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(attachmentListProvider(paperId)),
          ),
        ],
      ),
      floatingActionButton: access.canUploadPapers
          ? FloatingActionButton.extended(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Add Attachment'),
            )
          : null,
      body: attachmentsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No attachments found');
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
            children: [
              _AttachmentSummary(
                paperTitle: paperTitle,
                attachmentCount: items.length,
              ),
              const SizedBox(height: 20),
              const _AttachmentSectionTitle(),
              const SizedBox(height: 10),
              ...items.map(
                (attachment) => _AttachmentListCard(
                  fileName: attachment.fileName,
                  filePath: attachment.filePath,
                  displayOrder: attachment.displayOrder,
                  onOpen: () => _openFile(context, attachment.filePath),
                ),
              ),
            ],
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load attachments: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}

class _AttachmentSummary extends StatelessWidget {
  final String paperTitle;
  final int attachmentCount;

  const _AttachmentSummary({
    required this.paperTitle,
    required this.attachmentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.folder_copy_outlined,
              color: AttachmentScreen._gold,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paperTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$attachmentCount ${attachmentCount == 1 ? 'attachment' : 'attachments'}',
                  style: const TextStyle(
                    color: Color(0xFFD8E2FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentSectionTitle extends StatelessWidget {
  const _AttachmentSectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.attach_file_rounded,
          color: AttachmentScreen._cardBlue,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          'Files',
          style: TextStyle(
            color: Color(0xFF00184A),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AttachmentListCard extends StatelessWidget {
  final String fileName;
  final String filePath;
  final int? displayOrder;
  final VoidCallback onOpen;

  const _AttachmentListCard({
    required this.fileName,
    required this.filePath,
    required this.displayOrder,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = _isImage(fileName) || _isImage(filePath);

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE8EBF2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isImage
                      ? const Color(0xFFE0F8F1)
                      : const Color(0xFFFFEAEA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isImage ? Icons.image_outlined : Icons.picture_as_pdf_rounded,
                  color: isImage
                      ? const Color(0xFF16835B)
                      : const Color(0xFFE74C3C),
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF00184A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (displayOrder != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Display order $displayOrder',
                        style: const TextStyle(
                          color: Color(0xFF7D8CB2),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Open',
                onPressed: onOpen,
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  color: AttachmentScreen._cardBlue,
                ),
              ),
            ],
          ),
        ),
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
