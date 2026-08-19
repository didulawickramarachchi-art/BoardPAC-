import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../model/category_model.dart';
import '../model/category_request.dart';
import '../provider/category_provider.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final CategoryModel? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _displayOrderController = TextEditingController();

  bool _isSaving = false;
  PlatformFile? _image;

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color bgColor = Color(0xFFF6F7FB);

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    if (category != null) {
      _nameController.text = category.name;
      _displayNameController.text = category.displayName;
      _displayOrderController.text = category.displayOrder?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final displayOrderText = _displayOrderController.text.trim();

    setState(() => _isSaving = true);

    try {
      String? imageUrl = widget.category?.imageUrl;
      if (_image != null) {
        imageUrl = await ref
            .read(categoryRepositoryProvider)
            .uploadCategoryImage(
              fileName: _image!.name,
              filePath: _image!.path,
              fileBytes: _image!.bytes,
            );
        if (imageUrl.isEmpty) {
          throw StateError('The category image upload returned an empty URL.');
        }
      }
      final request = CategoryRequest(
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        displayOrder: displayOrderText.isEmpty
            ? null
            : int.parse(displayOrderText),
        imageUrl: imageUrl,
      );
      final repository = ref.read(categoryRepositoryProvider);
      if (_isEditing) {
        await repository.updateCategory(widget.category!.id, request);
      } else {
        await repository.createCategory(request);
      }

      ref.invalidate(categoryListProvider);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMessage.from(
                e,
                fallback: _isEditing
                    ? 'Failed to update category.'
                    : 'Failed to create category.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _chooseImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final image = result.files.single;
    if (image.size > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category image must be 5 MB or smaller.'),
          ),
        );
      }
      return;
    }
    setState(() => _image = image);
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
        title: Text(
          _isEditing ? 'Edit Category' : 'Create Category',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              const _HeaderCard(),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Category Details',
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isSaving ? null : _chooseImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _image?.bytes != null
                          ? Image.memory(_image!.bytes!, fit: BoxFit.cover)
                          : (widget.category?.imageUrl ?? '').trim().isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  widget.category!.imageUrl!.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const _ImagePrompt(editing: true),
                                ),
                                const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: ColoredBox(
                                    color: Color(0x9900184A),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      child: Text(
                                        'Tap to replace image',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _ImagePrompt(editing: _isEditing),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FormTextField(
                    controller: _nameController,
                    label: 'Name',
                    hintText: 'Example: BOARD_PACK',
                    textInputAction: TextInputAction.next,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 14),
                  _FormTextField(
                    controller: _displayNameController,
                    label: 'Display Name',
                    hintText: 'Example: Board Pack',
                    textInputAction: TextInputAction.next,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 14),
                  _FormTextField(
                    controller: _displayOrderController,
                    label: 'Display Order',
                    hintText: 'Example: 1',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    validator: _displayOrderValidator,
                    onSubmitted: (_) => _isSaving ? null : _save(),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Category',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  String? _displayOrderValidator(String? value) {
    final cleanValue = (value ?? '').trim();

    if (cleanValue.isEmpty) {
      return null;
    }

    final number = int.tryParse(cleanValue);
    if (number == null) {
      return 'Display order must be a number';
    }

    if (number < 0) {
      return 'Display order cannot be negative';
    }

    return null;
  }
}

class _ImagePrompt extends StatelessWidget {
  final bool editing;

  const _ImagePrompt({required this.editing});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate_outlined,
          size: 38,
          color: _CategoryFormScreenState.primaryBlue,
        ),
        const SizedBox(height: 8),
        Text(
          editing ? 'Add category image' : 'Add category image (optional)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

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
            color: primaryBlue.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_outlined,
              color: darkBlue,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Board Setup',
                  style: TextStyle(
                    color: Color(0xFFB9C4E2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'New Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create a grouping for meetings and papers',
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

  const _SectionCard({required this.title, required this.children});

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
            color: Colors.black.withValues(alpha: 0.035),
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

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const _FormTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
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
          borderSide: const BorderSide(color: Color(0xFFFFB52E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
