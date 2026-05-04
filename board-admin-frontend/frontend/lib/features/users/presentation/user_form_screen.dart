import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../model/user_model.dart';
import '../model/user_request.dart';
import '../provider/user_provider.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const UserFormScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _boardEmailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _jobTitleController;

  bool twoStepEnabled = false;
  String boardType = 'ORGANIZER';
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _displayNameController =
        TextEditingController(text: widget.user.displayName ?? '');
    _boardEmailController = TextEditingController(text: widget.user.boardEmail);
    _mobileController =
        TextEditingController(text: widget.user.mobileNumber ?? '');
    _jobTitleController =
        TextEditingController(text: widget.user.jobTitle ?? '');
    boardType = widget.user.boardType ?? 'ORGANIZER';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _boardEmailController.dispose();
    _mobileController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => isSaving = true);

    final request = UserRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      displayName: _displayNameController.text.trim(),
      boardEmail: _boardEmailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      jobTitle: _jobTitleController.text.trim(),
      boardType: boardType,
      officeEmail: null,
      officeNumber: null,
      twoStepEnabled: twoStepEnabled,
    );

    await ref.read(userListProvider.notifier).updateUser(widget.user.id, request);

    if (mounted) {
      setState(() => isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(controller: _firstNameController, hintText: 'First name'),
          const SizedBox(height: 12),
          AppTextField(controller: _lastNameController, hintText: 'Last name'),
          const SizedBox(height: 12),
          AppTextField(controller: _displayNameController, hintText: 'Display name'),
          const SizedBox(height: 12),
          AppTextField(controller: _boardEmailController, hintText: 'Board email'),
          const SizedBox(height: 12),
          AppTextField(controller: _mobileController, hintText: 'Mobile number'),
          const SizedBox(height: 12),
          AppTextField(controller: _jobTitleController, hintText: 'Job title'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: boardType,
            decoration: const InputDecoration(labelText: 'Board type'),
            items: const [
              DropdownMenuItem(value: 'MEMBER', child: Text('Member')),
              DropdownMenuItem(value: 'ORGANIZER', child: Text('Organizer')),
              DropdownMenuItem(value: 'SUPPORT_TEAM', child: Text('Support Team')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => boardType = value);
              }
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: twoStepEnabled,
            onChanged: (value) => setState(() => twoStepEnabled = value),
            title: const Text('Enable 2-Step Authentication'),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Save Changes',
            onPressed: _save,
            isLoading: isSaving,
          ),
        ],
      ),
    );
  }
}