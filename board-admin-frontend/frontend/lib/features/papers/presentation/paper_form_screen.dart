import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../model/paper_request.dart';
import '../provider/paper_provider.dart';

class PaperFormScreen extends ConsumerStatefulWidget {
  final int meetingId;

  const PaperFormScreen({
    super.key,
    required this.meetingId,
  });

  @override
  ConsumerState<PaperFormScreen> createState() => _PaperFormScreenState();
}

class _PaperFormScreenState extends ConsumerState<PaperFormScreen> {
  final _agendaItemIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _referenceController = TextEditingController();
  final _filePathController = TextEditingController();
  final _fileNameController = TextEditingController();
  final _versionController = TextEditingController(text: '1');
  final _disclaimerController = TextEditingController();

  String paperType = 'APPROVAL';
  bool requiresApproval = true;
  bool isMainPaper = true;
  bool isSaving = false;

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
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (!mounted) return;

    setState(() {
      _filePathController.text = file.path ?? '';
      _fileNameController.text = file.name;
    });
  }

  Future<void> _save() async {
    setState(() => isSaving = true);

    final request = PaperRequest(
      meetingId: widget.meetingId,
      agendaItemId: int.parse(_agendaItemIdController.text.trim()),
      paperType: paperType,
      title: _titleController.text.trim(),
      referenceNumber: _referenceController.text.trim(),
      filePath: _filePathController.text.trim(),
      fileName: _fileNameController.text.trim(),
      versionNumber: int.tryParse(_versionController.text.trim()),
      requiresApproval: requiresApproval,
      isMainPaper: isMainPaper,
      disclaimerMessage: _disclaimerController.text.trim(),
    );

    await ref
        .read(paperListProvider(widget.meetingId).notifier)
        .createPaper(request);

    if (mounted) {
      setState(() => isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _agendaItemIdController.dispose();
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
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _ModernTextField(
                  controller: _agendaItemIdController,
                  hintText: 'Agenda Item ID',
                  icon: Icons.format_list_numbered_rounded,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: paperType,
                  decoration: InputDecoration(
                    labelText: 'Paper Type',
                    prefixIcon: const Icon(
                      Icons.category_rounded,
                      color: navy,
                    ),
                    filled: true,
                    fillColor: iconBg.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: navy,
                        width: 1.4,
                      ),
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
                      color: iconBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: navy.withOpacity(0.08),
                      ),
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
        fillColor: iconBg.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: navy,
            width: 1.4,
          ),
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
        color: iconBg.withOpacity(0.45),
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
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}