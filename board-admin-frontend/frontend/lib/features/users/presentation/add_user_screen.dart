import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/network/api_error_message.dart';
import '../model/create_user_request.dart';
import '../provider/user_provider.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  String role = 'MEMBER';
  bool saving = false;

  static const navy = Color(0xFF12275B);
  static const gold = Color(0xFFFFB52E);
  static const background = Color(0xFFF6F7FB);

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if ([
      username,
      password,
      firstName,
      lastName,
      email,
    ].any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all required fields.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await ref
          .read(userListProvider.notifier)
          .createUser(
            CreateUserRequest(
              username: username.text.trim(),
              password: password.text,
              firstName: firstName.text.trim(),
              lastName: lastName.text.trim(),
              boardEmail: email.text.trim(),
              role: role,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        final errorMessage = ApiErrorMessage.from(error);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Add User',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            title: 'Account Details',
            children: [
              AppTextField(controller: username, hintText: 'Username'),
              const SizedBox(height: 12),
              AppTextField(
                controller: password,
                hintText: 'Temporary password',
                obscureText: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'User Details',
            children: [
              AppTextField(controller: firstName, hintText: 'First name'),
              const SizedBox(height: 12),
              AppTextField(controller: lastName, hintText: 'Last name'),
              const SizedBox(height: 12),
              AppTextField(controller: email, hintText: 'Board email'),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Role Type',
            children: [
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: _decoration('Role'),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  DropdownMenuItem(
                    value: 'SECRETARY',
                    child: Text('Secretary'),
                  ),
                  DropdownMenuItem(value: 'MEMBER', child: Text('Member')),
                ],
                onChanged: saving
                    ? null
                    : (value) => setState(() => role = value ?? 'MEMBER'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Create User', onPressed: save, isLoading: saving),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: gold, width: 1.5),
    ),
  );
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00184A),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}
