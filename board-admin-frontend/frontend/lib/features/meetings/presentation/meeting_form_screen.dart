import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../categories/model/category_model.dart';
import '../../categories/provider/category_provider.dart';
import '../../subcategories/model/subcategory_model.dart';
import '../../subcategories/provider/subcategory_provider.dart';
import '../model/meeting_request.dart';
import '../provider/meeting_provider.dart';

class MeetingFormScreen extends ConsumerStatefulWidget {
  const MeetingFormScreen({super.key});

  @override
  ConsumerState<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends ConsumerState<MeetingFormScreen> {
  final _titleController = TextEditingController();
  final _meetingDateController = TextEditingController();
  final _targetDateController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String meetingType = 'MEETING';
  int? selectedCategoryId;
  int? selectedSubcategoryId;
  PlatformFile? _image;
  bool isSaving = false;

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  Future<void> _pickMeetingDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              secondary: gold,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: primaryBlue,
                secondary: gold,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        _meetingDateController.text = _formatLocalDateTime(selectedDateTime);
      }
    }
  }

  Future<void> _pickTargetDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              secondary: gold,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: primaryBlue,
                secondary: gold,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        _targetDateController.text = _formatLocalDateTime(selectedDateTime);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _meetingDateController.dispose();
    _targetDateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final categoryId = selectedCategoryId;
    if (categoryId == null) {
      _showValidationMessage('Please select a category.');
      return;
    }

    final subcategoryId = selectedSubcategoryId;
    if (subcategoryId == null) {
      _showValidationMessage('Please select a subcategory.');
      return;
    }

    setState(() => isSaving = true);

    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await ref
            .read(meetingRepositoryProvider)
            .uploadMeetingImage(
              fileName: _image!.name,
              filePath: _image!.path,
              fileBytes: _image!.bytes,
            );
        if (imageUrl.isEmpty) {
          throw StateError('The meeting image upload returned an empty URL.');
        }
      }

      final request = MeetingRequest(
        title: _titleController.text.trim(),
        type: meetingType,
        meetingDateTime: _meetingDateController.text.trim(),
        targetDateTime: _targetDateController.text.trim().isEmpty
            ? null
            : _targetDateController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
      );

      await ref.read(meetingListProvider.notifier).createMeeting(request);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMessage.from(e, fallback: 'Failed to create meeting.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
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
      _showValidationMessage('Meeting image must be 5 MB or smaller.');
      return;
    }
    setState(() => _image = image);
  }

  String _formatLocalDateTime(DateTime dateTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${dateTime.year}-'
        '${twoDigits(dateTime.month)}-'
        '${twoDigits(dateTime.day)}T'
        '${twoDigits(dateTime.hour)}:'
        '${twoDigits(dateTime.minute)}:00';
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final subcategoriesAsync = ref.watch(subcategoryListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Create Meeting',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _HeaderCard(meetingType: meetingType),

          const SizedBox(height: 18),

          _SectionCard(
            title: 'Meeting Image',
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isSaving ? null : _chooseImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _image?.bytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_image!.bytes!, fit: BoxFit.cover),
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
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 38,
                              color: primaryBlue,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add meeting image (optional)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Meeting Details',
            children: [
              AppTextField(
                controller: _titleController,
                hintText: 'Meeting title',
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: meetingType,
                decoration: _dropdownDecoration('Meeting Type'),
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primaryBlue,
                ),
                items: const [
                  DropdownMenuItem(value: 'MEETING', child: Text('Meeting')),
                  DropdownMenuItem(value: 'CIRCULAR', child: Text('Circular')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      meetingType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickMeetingDateTime,
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: _meetingDateController,
                    hintText: 'Select Meeting Date & Time',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickTargetDateTime,
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: _targetDateController,
                    hintText: 'Select Target Date & Time',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Location & Description',
            children: [
              AppTextField(
                controller: _locationController,
                hintText: 'Location',
              ),

              const SizedBox(height: 12),

              AppTextField(
                controller: _descriptionController,
                hintText: 'Description',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Reference Details',
            children: [
              categoriesAsync.when(
                data: (categories) => _buildCategoryDropdown(categories),
                loading: () => const _DropdownLoading(label: 'Category'),
                error: (error, _) => _DropdownError(
                  message: 'Failed to load categories: $error',
                  onRetry: () {
                    ref.invalidate(categoryListProvider);
                  },
                ),
              ),

              const SizedBox(height: 12),

              subcategoriesAsync.when(
                data: (subcategories) =>
                    _buildSubcategoryDropdown(subcategories),
                loading: () => const _DropdownLoading(label: 'Subcategory'),
                error: (error, _) => _DropdownError(
                  message: 'Failed to load subcategories: $error',
                  onRetry: () {
                    ref.invalidate(subcategoryListProvider);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          AppButton(
            label: 'Create Meeting',
            onPressed: _save,
            isLoading: isSaving,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(List<CategoryModel> categories) {
    return DropdownButtonFormField<int>(
      initialValue: selectedCategoryId,
      decoration: _dropdownDecoration('Category'),
      dropdownColor: Theme.of(context).colorScheme.surface,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
      items: categories
          .map(
            (category) => DropdownMenuItem<int>(
              value: category.id,
              child: Text(
                _displayName(category.displayName, category.name),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: categories.isEmpty
          ? null
          : (value) {
              setState(() {
                selectedCategoryId = value;
                selectedSubcategoryId = null;
              });
            },
    );
  }

  Widget _buildSubcategoryDropdown(List<SubcategoryModel> subcategories) {
    final filteredSubcategories = selectedCategoryId == null
        ? <SubcategoryModel>[]
        : subcategories
              .where(
                (subcategory) => subcategory.categoryId == selectedCategoryId,
              )
              .toList();

    return DropdownButtonFormField<int>(
      initialValue: selectedSubcategoryId,
      decoration: _dropdownDecoration('Subcategory'),
      dropdownColor: Theme.of(context).colorScheme.surface,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
      items: filteredSubcategories
          .map(
            (subcategory) => DropdownMenuItem<int>(
              value: subcategory.id,
              child: Text(
                _displayName(subcategory.displayName, subcategory.name),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: filteredSubcategories.isEmpty
          ? null
          : (value) {
              setState(() {
                selectedSubcategoryId = value;
              });
            },
    );
  }

  String _displayName(String displayName, String name) {
    if (displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    if (name.trim().isNotEmpty) {
      return name.trim();
    }

    return 'Unnamed';
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String meetingType;

  const _HeaderCard({required this.meetingType});

  static const Color primaryBlue = Color(0xFF12275B);

  static const Color gold = Color(0xFFFFB52E);

  @override
  Widget build(BuildContext context) {
    final isCircular = meetingType == 'CIRCULAR';

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
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCircular ? Icons.campaign_outlined : Icons.event_note_outlined,
              color: const Color(0xFF00184A),
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New',
                  style: TextStyle(
                    color: Color(0xFFB9C4E2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  isCircular ? 'Circular' : 'Meeting',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Fill the details below to continue',
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

class _DropdownLoading extends StatelessWidget {
  final String label;

  const _DropdownLoading({required this.label});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      child: const SizedBox(
        height: 22,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _DropdownError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DropdownError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
