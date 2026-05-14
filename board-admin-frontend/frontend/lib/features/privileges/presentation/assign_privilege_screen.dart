import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../model/privilege_request.dart';
import '../provider/privilege_provider.dart';

class AssignPrivilegeScreen extends ConsumerStatefulWidget {
  const AssignPrivilegeScreen({super.key});

  @override
  ConsumerState<AssignPrivilegeScreen> createState() =>
      _AssignPrivilegeScreenState();
}

class _AssignPrivilegeScreenState extends ConsumerState<AssignPrivilegeScreen> {
  final _userIdController = TextEditingController();
  final _subcategoryIdController = TextEditingController();
  final _displaySequenceController = TextEditingController();

  String selectedRole = 'MEMBER';
  bool isSaving = false;

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

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
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Assign Privilege',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _HeaderCard(),

          const SizedBox(height: 18),

          _SectionCard(
            title: 'Privilege Details',
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
                initialValue: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Assigned Role',
                  labelStyle: const TextStyle(
                    color: Color(0xFF7D8CB2),
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: bgColor,
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
                    value: 'MEMBER',
                    child: Text('Member'),
                  ),
                  DropdownMenuItem(
                    value: 'SECRETARY',
                    child: Text('Secretary'),
                  ),
                  DropdownMenuItem(
                    value: 'VIEW_ONLY',
                    child: Text('View Only'),
                  ),
                  DropdownMenuItem(
                    value: 'COMMENT_ONLY',
                    child: Text('Comment Only'),
                  ),
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
            ],
          ),

          const SizedBox(height: 22),

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

class _HeaderCard extends StatelessWidget {
  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: darkBlue,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access Control',
                  style: TextStyle(
                    color: Color(0xFFB9C4E2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Assign New Privilege',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Give user access to selected subcategory',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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