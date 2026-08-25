import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/agendas/model/agenda_item_model.dart';
import 'package:frontend/features/agendas/provider/agenda_provider.dart';

import '../../../core/widgets/app_button.dart';
import '../model/paper_request.dart';
import '../provider/paper_provider.dart';

class PaperFormScreen extends ConsumerStatefulWidget {
  final int meetingId;

  const PaperFormScreen({super.key, required this.meetingId});

  @override
  ConsumerState<PaperFormScreen> createState() => _PaperFormScreenState();
}

class _PaperFormScreenState extends ConsumerState<PaperFormScreen> {
  final _titleController = TextEditingController();
  final _referenceController = TextEditingController();
  final _filePathController = TextEditingController();
  final _fileNameController = TextEditingController();
  final _versionController = TextEditingController(text: '1');
  final _disclaimerController = TextEditingController();

  String paperType = 'APPROVAL';
  int? selectedAgendaItemId;
  bool requiresApproval = true;
  bool isMainPaper = true;
  bool isSaving = false;
  PlatformFile? selectedFile;
  Uint8List? selectedFileBytes;
  String? selectedFilePath;

  static const Color navy = Color(0xFF14275B);
  static const Color bgColor = Color(0xFFF6F7FC);
  static const Color cardColor = Colors.white;
  static const Color iconBg = Color(0xFFE9ECF3);
  static const Color arrowBg = Color(0xFFFFF1D8);
  static const Color subTextColor = Color(0xFF6E7FA8);

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'gif', 'webp'],
      allowMultiple: false,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (!mounted) return;

    setState(() {
      selectedFile = file;
      selectedFileBytes = file.bytes;
      selectedFilePath = file.path;
      _filePathController.text = file.path ?? '';
      _fileNameController.text = file.name;
    });
  }

  Future<void> _save() async {
    setState(() => isSaving = true);

    final versionNumber = int.tryParse(_versionController.text.trim());

    try {
      var filePath = _filePathController.text.trim();
      var fileName = _fileNameController.text.trim();

      if (selectedFile != null) {
        fileName = fileName.isEmpty ? selectedFile!.name : fileName;
        filePath = await ref
            .read(paperRepositoryProvider)
            .uploadAttachment(
              fileName: fileName,
              meetingId: widget.meetingId,
              filePath: selectedFilePath,
              fileBytes: selectedFileBytes,
            );
      }

      final request = PaperRequest(
        meetingId: widget.meetingId,
        agendaItemId: selectedAgendaItemId,
        paperType: paperType,
        title: _titleController.text.trim(),
        referenceNumber: _referenceController.text.trim(),
        filePath: filePath,
        fileName: fileName,
        versionNumber: versionNumber,
        requiresApproval: requiresApproval,
        isMainPaper: isMainPaper,
        disclaimerMessage: _disclaimerController.text.trim(),
      );

      await ref
          .read(paperListProvider(widget.meetingId).notifier)
          .createPaper(request);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create paper: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _referenceController.dispose();
    _filePathController.dispose();
    _fileNameController.dispose();
    _versionController.dispose();
    _disclaimerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agendaItemsAsync = ref.watch(agendaItemProvider(widget.meetingId));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Create Paper',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                agendaItemsAsync.when(
                  data: (items) => _AgendaItemDropdown(
                    items: items,
                    value: selectedAgendaItemId,
                    onChanged: (value) {
                      setState(() => selectedAgendaItemId = value);
                    },
                  ),
                  loading: () => const _LoadingDropdownField(),
                  error: (error, _) => _AgendaLoadError(
                    message: 'Failed to load agenda items',
                    onRetry: () {
                      ref.invalidate(agendaItemProvider(widget.meetingId));
                    },
                  ),
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: paperType,
                  decoration: InputDecoration(
                    labelText: 'Paper Type',
                    prefixIcon: const Icon(Icons.category_rounded, color: navy),
                    filled: true,
                    fillColor: iconBg.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: navy, width: 1.4),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'APPROVAL',
                      child: Text('Approval'),
                    ),
                    DropdownMenuItem(
                      value: 'INFORMATION',
                      child: Text('Information'),
                    ),
                    DropdownMenuItem(
                      value: 'DISCUSSION_ITEM',
                      child: Text('Discussion Item'),
                    ),
                    DropdownMenuItem(
                      value: 'DISCUSSION_PAPER',
                      child: Text('Discussion Paper'),
                    ),
                    DropdownMenuItem(
                      value: 'SUPPORTING_DOCUMENT',
                      child: Text('Supporting Document'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => paperType = value);
                    }
                  },
                ),

                const SizedBox(height: 14),

                _ModernTextField(
                  controller: _titleController,
                  hintText: 'Paper Title',
                  icon: Icons.description_rounded,
                ),

                const SizedBox(height: 14),

                _ModernTextField(
                  controller: _referenceController,
                  hintText: 'Reference Number',
                  icon: Icons.confirmation_number_rounded,
                ),

                const SizedBox(height: 16),

                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: navy.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: arrowBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: navy,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Choose PDF or Image',
                                style: TextStyle(
                                  color: navy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fileNameController.text.isEmpty
                                    ? 'Upload your paper document'
                                    : _fileNameController.text,
                                style: const TextStyle(
                                  color: subTextColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: navy,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                _ModernTextField(
                  controller: _fileNameController,
                  hintText: 'File Name',
                  icon: Icons.insert_drive_file_rounded,
                ),

                const SizedBox(height: 14),

                _ModernTextField(
                  controller: _versionController,
                  hintText: 'Version Number',
                  icon: Icons.system_update_alt_rounded,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 14),

                _ModernTextField(
                  controller: _disclaimerController,
                  hintText: 'Disclaimer Message',
                  icon: Icons.warning_amber_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: 18),

                _ModernSwitchTile(
                  title: 'Requires Approval',
                  subtitle: 'Paper requires approval process',
                  value: requiresApproval,
                  icon: Icons.verified_rounded,
                  onChanged: (value) {
                    setState(() => requiresApproval = value);
                  },
                ),

                const SizedBox(height: 12),

                _ModernSwitchTile(
                  title: 'Main Paper',
                  subtitle: 'Set as the main meeting paper',
                  value: isMainPaper,
                  icon: Icons.star_rounded,
                  onChanged: (value) {
                    setState(() => isMainPaper = value);
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: AppButton(
                    label: 'Create Paper',
                    onPressed: _save,
                    isLoading: isSaving,
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

class _AgendaItemDropdown extends StatelessWidget {
  final List<AgendaItemModel> items;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _AgendaItemDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
  });

  static const Color navy = Color(0xFF14275B);
  static const Color iconBg = Color(0xFFE9ECF3);

  @override
  Widget build(BuildContext context) {
    final hasSelectedItem = items.any((item) => item.id == value);
    final effectiveValue = hasSelectedItem ? value : null;

    return DropdownButtonFormField<int>(
      key: ValueKey(effectiveValue),
      initialValue: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Agenda Item',
        prefixIcon: const Icon(Icons.format_list_numbered_rounded, color: navy),
        suffixIcon: effectiveValue == null
            ? null
            : IconButton(
                tooltip: 'Clear agenda item',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => onChanged(null),
              ),
        filled: true,
        fillColor: iconBg.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: navy, width: 1.4),
        ),
      ),
      hint: const Text('No agenda item'),
      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: item.id,
          child: Text(
            _agendaItemLabel(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static String _agendaItemLabel(AgendaItemModel item) {
    final number = item.numberLabel?.trim();
    if (number != null && number.isNotEmpty) {
      return '$number - ${item.title}';
    }

    return item.title.isEmpty ? 'Agenda Item ${item.id}' : item.title;
  }
}

class _LoadingDropdownField extends StatelessWidget {
  const _LoadingDropdownField();

  static const Color navy = Color(0xFF14275B);
  static const Color iconBg = Color(0xFFE9ECF3);

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Agenda Item',
        prefixIcon: const Icon(Icons.format_list_numbered_rounded, color: navy),
        filled: true,
        fillColor: iconBg.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      child: const Text('Loading agenda items...'),
    );
  }
}

class _AgendaLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AgendaLoadError({required this.message, required this.onRetry});

  static const Color navy = Color(0xFF14275B);
  static const Color iconBg = Color(0xFFE9ECF3);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: iconBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: navy),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _ModernTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  static const Color navy = Color(0xFF14275B);
  static const Color iconBg = Color(0xFFE9ECF3);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: navy),
        filled: true,
        fillColor: iconBg.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: navy, width: 1.4),
        ),
      ),
    );
  }
}

class _ModernSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _ModernSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  static const Color navy = Color(0xFF14275B);
  static const Color iconBg = Color(0xFFE9ECF3);
  static const Color subTextColor = Color(0xFF6E7FA8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
