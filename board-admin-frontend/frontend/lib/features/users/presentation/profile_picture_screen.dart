import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import '../provider/user_provider.dart';

class ProfilePictureScreen extends ConsumerStatefulWidget {
  const ProfilePictureScreen({super.key});

  @override
  ConsumerState<ProfilePictureScreen> createState() =>
      _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends ConsumerState<ProfilePictureScreen> {
  static const _primaryBlue = Color(0xFF12275B);
  static const _gold = Color(0xFFFFB52E);

  PlatformFile? _selectedFile;
  bool _uploading = false;
  bool _resettingPassword = false;
  bool _updatingTwoFactor = false;
  bool? _twoFactorEnabled;

  Future<void> _setTwoFactor(bool enabled) async {
    if (_updatingTwoFactor) return;

    final previousValue = _twoFactorEnabled ?? !enabled;
    setState(() {
      _twoFactorEnabled = enabled;
      _updatingTwoFactor = true;
    });
    try {
      await ref.read(userRepositoryProvider).updateOwnTwoFactor(enabled);
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Two-factor authentication enabled. An OTP will be required at your next login.'
                  : 'Two-factor authentication disabled.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _twoFactorEnabled = previousValue);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update two-factor authentication.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingTwoFactor = false);
    }
  }

  Future<void> _choosePicture() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture must be 5 MB or smaller'),
          ),
        );
      }
      return;
    }

    setState(() => _selectedFile = file);
  }

  Future<void> _uploadPicture() async {
    final file = _selectedFile;
    if (file == null || _uploading) return;

    setState(() => _uploading = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .uploadProfilePicture(
            fileName: file.name,
            filePath: file.path,
            fileBytes: file.bytes,
          );
      ref.invalidate(currentUserProvider);
      ref.invalidate(profilePictureProvider);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update profile picture: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _changePassword(String email) async {
    if (_resettingPassword) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password?'),
        content: const Text(
          'We will email a secure password-change link to your registered '
          'email address. The link will expire after a limited time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resettingPassword = true);
    try {
      final resetUrl = Uri.base
          .replace(path: '/', query: null, fragment: '/reset-password')
          .toString();
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: email, resetUrl: resetUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password-change email sent. Check your inbox.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not send the password email. Please try again later.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resettingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final twoFactorEnabled = _twoFactorEnabled ?? user?.twoStepEnabled ?? false;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.username ?? 'User';
    final initials = _initials(displayName);
    final imageUrl = user?.profilePictureUrl?.trim();
    final picture = imageUrl?.isNotEmpty == true
        ? ref
              .watch(profilePictureProvider((userId: user!.id, url: imageUrl!)))
              .valueOrNull
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('User Profile Settings'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PicturePreview(
                      selectedBytes: _selectedFile?.bytes,
                      imageBytes: picture,
                      initials: initials,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: _primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a JPG, PNG, or WebP image up to 5 MB.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7380A4)),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _uploading ? null : _choosePicture,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _selectedFile == null
                              ? 'Choose Picture'
                              : 'Choose Another Picture',
                        ),
                      ),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _uploading ? null : _uploadPicture,
                          icon: _uploading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            _uploading ? 'Uploading...' : 'Save Picture',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile.adaptive(
                        value: twoFactorEnabled,
                        onChanged: user == null || _updatingTwoFactor
                            ? null
                            : _setTwoFactor,
                        activeThumbColor: _gold,
                        activeTrackColor: _primaryBlue,
                        inactiveThumbColor: const Color(0xFF8E95A3),
                        inactiveTrackColor: const Color(0xFFD8DCE5),
                        secondary: _updatingTwoFactor
                            ? const SizedBox.square(
                                dimension: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.verified_user_outlined,
                                color: _primaryBlue,
                              ),
                        title: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Two-Factor Authentication',
                                style: TextStyle(
                                  color: _primaryBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: twoFactorEnabled
                                    ? _primaryBlue
                                    : const Color(0xFFE1E4EA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                twoFactorEnabled ? 'ON' : 'OFF',
                                style: TextStyle(
                                  color: twoFactorEnabled
                                      ? _gold
                                      : const Color(0xFF626B7A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Text(
                          'Require an email OTP when signing in',
                          style: TextStyle(
                            color: Color(0xFF7380A4),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFF0F3F8),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: _primaryBlue,
                              size: 21,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password',
                                style: TextStyle(
                                  color: _primaryBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Keep your account secure',
                                style: TextStyle(
                                  color: Color(0xFF7380A4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: user == null || _resettingPassword
                            ? null
                            : () => _changePassword(user.boardEmail),
                        icon: _resettingPassword
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.password_rounded),
                        label: Text(
                          _resettingPassword
                              ? 'Sending Email...'
                              : 'Change Password',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }
}

class _PicturePreview extends StatelessWidget {
  final Uint8List? selectedBytes;
  final Uint8List? imageBytes;
  final String initials;

  const _PicturePreview({
    required this.selectedBytes,
    required this.imageBytes,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback() => ColoredBox(
      color: _ProfilePictureScreenState._gold,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: _ProfilePictureScreenState._primaryBlue,
            fontSize: 38,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    Widget picture;
    if (selectedBytes != null) {
      picture = Image.memory(
        selectedBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else if (imageBytes != null) {
      picture = Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else {
      picture = fallback();
    }

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _ProfilePictureScreenState._gold, width: 4),
      ),
      child: ClipOval(child: picture),
    );
  }
}
