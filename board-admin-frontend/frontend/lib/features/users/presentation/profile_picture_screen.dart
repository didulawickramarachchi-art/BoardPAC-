import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/user_provider.dart';

class ProfilePictureScreen extends ConsumerStatefulWidget {
  const ProfilePictureScreen({super.key});

  @override
  ConsumerState<ProfilePictureScreen> createState() =>
      _ProfilePictureScreenState();
}

class _ProfilePictureScreenState
    extends ConsumerState<ProfilePictureScreen> {
  static const _primaryBlue = Color(0xFF12275B);
  static const _gold = Color(0xFFFFB52E);

  PlatformFile? _selectedFile;
  bool _uploading = false;

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
      await ref.read(userRepositoryProvider).uploadProfilePicture(
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.username ?? 'User';
    final initials = _initials(displayName);
    final imageUrl = user?.profilePictureUrl?.trim();
    final picture = imageUrl?.isNotEmpty == true
        ? ref.watch(profilePictureProvider(imageUrl!)).valueOrNull
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Change Profile Picture'),
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
