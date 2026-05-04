import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../model/paper_request.dart';
import '../provider/paper_provider.dart';

class PaperFormScreen extends ConsumerStatefulWidget {
  final int meetingId;

  const PaperFormScreen({super.key, required this.meetingId});

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Paper')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(
            controller: _agendaItemIdController,
            hintText: 'Agenda Item ID',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: paperType,
            decoration: const InputDecoration(labelText: 'Paper Type'),
            items: const [
              DropdownMenuItem(value: 'APPROVAL', child: Text('Approval')),
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
              if (value != null) setState(() => paperType = value);
            },
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _titleController, hintText: 'Paper title'),
          const SizedBox(height: 12),
          AppTextField(
            controller: _referenceController,
            hintText: 'Reference number',
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _filePathController, hintText: 'File path'),
          const SizedBox(height: 12),
          AppTextField(controller: _fileNameController, hintText: 'File name'),
          const SizedBox(height: 12),
          AppTextField(
            controller: _versionController,
            hintText: 'Version number',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _disclaimerController,
            hintText: 'Disclaimer message',
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: requiresApproval,
            onChanged: (value) => setState(() => requiresApproval = value),
            title: const Text('Requires Approval'),
          ),
          SwitchListTile(
            value: isMainPaper,
            onChanged: (value) => setState(() => isMainPaper = value),
            title: const Text('Main Paper'),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Create Paper',
            onPressed: _save,
            isLoading: isSaving,
          ),
        ],
      ),
    );
  }
}
