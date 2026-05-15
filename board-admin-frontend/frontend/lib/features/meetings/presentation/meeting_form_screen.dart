import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../model/meeting_request.dart';
import '../provider/meeting_provider.dart';

class MeetingFormScreen extends ConsumerStatefulWidget {
  const MeetingFormScreen({super.key});

  @override
  ConsumerState<MeetingFormScreen> createState() =>
      _MeetingFormScreenState();
}

class _MeetingFormScreenState
    extends ConsumerState<MeetingFormScreen> {
  final _titleController = TextEditingController();
  final _meetingDateController = TextEditingController();
  final _targetDateController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryIdController = TextEditingController();
  final _subcategoryIdController = TextEditingController();
  final _createdByController =
      TextEditingController(text: '1');

  String meetingType = 'MEETING';
  bool isSaving = false;

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  int? _readRequiredInt(
    TextEditingController controller,
    String fieldName,
  ) {
    final value = int.tryParse(controller.text.trim());

    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid $fieldName.',
          ),
        ),
      );
    }

    return value;
  }

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

        _meetingDateController.text =
            selectedDateTime.toIso8601String();
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

        _targetDateController.text =
            selectedDateTime.toIso8601String();
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
    _categoryIdController.dispose();
    _subcategoryIdController.dispose();
    _createdByController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final categoryId = _readRequiredInt(
      _categoryIdController,
      'Category ID',
    );

    if (categoryId == null) return;

    final subcategoryId = _readRequiredInt(
      _subcategoryIdController,
      'Subcategory ID',
    );

    if (subcategoryId == null) return;

    final createdByUserId = _readRequiredInt(
      _createdByController,
      'Created By User ID',
    );

    if (createdByUserId == null) return;

    final request = MeetingRequest(
      title: _titleController.text.trim(),
      type: meetingType,
      meetingDateTime:
          _meetingDateController.text.trim(),
      targetDateTime:
          _targetDateController.text.trim().isEmpty
              ? null
              : _targetDateController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      createdByUserId: createdByUserId,
    );

    setState(() => isSaving = true);

    try {
      await ref
          .read(meetingListProvider.notifier)
          .createMeeting(request);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create meeting: $e',
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
          'Create Meeting',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          24,
        ),
        children: [
          _HeaderCard(meetingType: meetingType),

          const SizedBox(height: 18),

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
                decoration:
                    _dropdownDecoration('Meeting Type'),
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primaryBlue,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'MEETING',
                    child: Text('Meeting'),
                  ),
                  DropdownMenuItem(
                    value: 'CIRCULAR',
                    child: Text('Circular'),
                  ),
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
                    controller:
                        _meetingDateController,
                    hintText:
                        'Select Meeting Date & Time',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickTargetDateTime,
                child: AbsorbPointer(
                  child: AppTextField(
                    controller:
                        _targetDateController,
                    hintText:
                        'Select Target Date & Time',
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
              AppTextField(
                controller: _categoryIdController,
                hintText: 'Category ID',
                keyboardType:
                    TextInputType.number,
              ),

              const SizedBox(height: 12),

              AppTextField(
                controller:
                    _subcategoryIdController,
                hintText: 'Subcategory ID',
                keyboardType:
                    TextInputType.number,
              ),

              const SizedBox(height: 12),

              AppTextField(
                controller: _createdByController,
                hintText:
                    'Created By User ID',
                keyboardType:
                    TextInputType.number,
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

  InputDecoration _dropdownDecoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,
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
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String meetingType;

  const _HeaderCard({
    required this.meetingType,
  });

  static const Color primaryBlue =
      Color(0xFF12275B);

  static const Color darkBlue =
      Color(0xFF00184A);

  static const Color gold =
      Color(0xFFFFB52E);

  @override
  Widget build(BuildContext context) {
    final isCircular =
        meetingType == 'CIRCULAR';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(
              0.20,
            ),
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
              isCircular
                  ? Icons.campaign_outlined
                  : Icons.event_note_outlined,
              color: darkBlue,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New',
                  style: TextStyle(
                    color:
                        Color(0xFFB9C4E2),
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  isCircular
                      ? 'Circular'
                      : 'Meeting',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Fill the details below to continue',
                  style: TextStyle(
                    color:
                        Color(0xFFFFD27A),
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
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

  static const Color darkBlue =
      Color(0xFF00184A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.035,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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