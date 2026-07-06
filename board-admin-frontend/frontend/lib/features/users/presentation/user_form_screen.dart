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
  String role = 'MEMBER';
  bool isSaving = false;

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

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

    role = widget.user.role?.toUpperCase() ?? 'MEMBER';
    twoStepEnabled = widget.user.twoStepEnabled ?? false;
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
      role: role,
      officeEmail: null,
      officeNumber: null,
      twoStepEnabled: twoStepEnabled,
    );

    await ref.read(userListProvider.notifier).updateUser(
          widget.user.id,
          request,
        );

    if (mounted) {
      setState(() => isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${widget.user.firstName} ${widget.user.lastName}'.trim();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit User',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _UserHeaderCard(
            fullName: fullName.isEmpty ? 'Unknown User' : fullName,
            email: widget.user.boardEmail,
          ),

          const SizedBox(height: 18),

          _SectionCard(
            title: 'Personal Details',
            children: [
              AppTextField(
                controller: _firstNameController,
                hintText: 'First name',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _lastNameController,
                hintText: 'Last name',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _displayNameController,
                hintText: 'Display name',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Contact Details',
            children: [
              AppTextField(
                controller: _boardEmailController,
                hintText: 'Board email',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _mobileController,
                hintText: 'Mobile number',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _jobTitleController,
                hintText: 'Job title',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Role Assignment',
            children: [
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: const TextStyle(
                    color: Color(0xFF7D8CB2),
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: gold,
                      width: 1.5,
                    ),
                  ),
                ),
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primaryBlue,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text('Admin'),
                  ),
                  DropdownMenuItem(
                    value: 'SECRETARY',
                    child: Text('Secretary'),
                  ),
                  DropdownMenuItem(
                    value: 'MEMBER',
                    child: Text('Member'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => role = value);
                  }
                },
              ),

              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: twoStepEnabled,
                  activeThumbColor: gold,
                  activeTrackColor: gold.withOpacity(0.35),
                  inactiveThumbColor: Colors.white,
                  title: const Text(
                    '2-Step Authentication',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Add extra protection to this account',
                    style: TextStyle(
                      color: Color(0xFF7D8CB2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => twoStepEnabled = value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

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

class _UserHeaderCard extends StatelessWidget {
  final String fullName;
  final String email;

  const _UserHeaderCard({
    required this.fullName,
    required this.email,
  });

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(fullName);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: darkBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editing User',
                  style: TextStyle(
                    color: Color(0xFFB9C4E2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFD27A),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  static const Color darkBlue = Color(0xFF00184A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 14),

          ...children,
        ],
      ),
    );
  }
}

String _getInitials(String name) {
  final cleanName = name.trim();

  if (cleanName.isEmpty) return 'U';

  final parts = cleanName.split(RegExp(r'\s+'));

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}