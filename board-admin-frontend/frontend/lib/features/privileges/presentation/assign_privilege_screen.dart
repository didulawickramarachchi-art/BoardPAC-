import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../model/privilege_request.dart';
import '../provider/privilege_provider.dart';

class AssignPrivilegeScreen extends ConsumerStatefulWidget {
  const AssignPrivilegeScreen({super.key});

  @override
  ConsumerState<AssignPrivilegeScreen> createState() => _AssignPrivilegeScreenState();
}

class _AssignPrivilegeScreenState extends ConsumerState<AssignPrivilegeScreen> {
  final _userIdController = TextEditingController();
  final _subcategoryIdController = TextEditingController();
  final _displaySequenceController = TextEditingController();

  String selectedRole = 'MEMBER';
  bool isSaving = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _subcategoryIdController.dispose();
    _displaySequenceController.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    setState(() => isSaving = true);

    final request = PrivilegeRequest(
      userId: int.parse(_userIdController.text.trim()),
      subcategoryId: int.parse(_subcategoryIdController.text.trim()),
      assignedRole: selectedRole,
      displaySequence: _displaySequenceController.text.trim().isEmpty
          ? null
          : int.parse(_displaySequenceController.text.trim()),
    );

    await ref.read(privilegeListProvider.notifier).assign(request);

    if (mounted) {
      setState(() => isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Privilege'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(
            controller: _userIdController,
            hintText: 'User ID',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _subcategoryIdController,
            hintText: 'Subcategory ID',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: 'Assigned Role'),
            items: const [
              DropdownMenuItem(value: 'MEMBER', child: Text('Member')),
              DropdownMenuItem(value: 'SECRETARY', child: Text('Secretary')),
              DropdownMenuItem(value: 'VIEW_ONLY', child: Text('View Only')),
              DropdownMenuItem(value: 'COMMENT_ONLY', child: Text('Comment Only')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedRole = value);
              }
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _displaySequenceController,
            hintText: 'Display Sequence',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Assign Privilege',
            onPressed: _assign,
            isLoading: isSaving,
          ),
        ],
      ),
    );
  }
}