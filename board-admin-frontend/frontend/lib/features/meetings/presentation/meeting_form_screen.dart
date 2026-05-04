import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
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
  final _categoryIdController = TextEditingController();
  final _subcategoryIdController = TextEditingController();
  final _createdByController = TextEditingController(text: '1');

  String meetingType = 'MEETING';
  bool isSaving = false;

  int? _readRequiredInt(TextEditingController controller, String fieldName) {
    final value = int.tryParse(controller.text.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid $fieldName.')),
      );
    }
    return value;
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
    final categoryId = _readRequiredInt(_categoryIdController, 'Category ID');
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
      meetingDateTime: _meetingDateController.text.trim(),
      targetDateTime: _targetDateController.text.trim().isEmpty
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
      await ref.read(meetingListProvider.notifier).createMeeting(request);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create meeting: $e')),
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
      appBar: AppBar(title: const Text('Create Meeting')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(controller: _titleController, hintText: 'Meeting title'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: meetingType,
            decoration: const InputDecoration(labelText: 'Meeting Type'),
            items: const [
              DropdownMenuItem(value: 'MEETING', child: Text('Meeting')),
              DropdownMenuItem(value: 'CIRCULAR', child: Text('Circular')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => meetingType = value);
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _meetingDateController,
            hintText: 'Meeting date time (2026-05-10T10:00:00)',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _targetDateController,
            hintText: 'Target date time (optional)',
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _locationController, hintText: 'Location'),
          const SizedBox(height: 12),
          AppTextField(
            controller: _descriptionController,
            hintText: 'Description',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _categoryIdController,
            hintText: 'Category ID',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _subcategoryIdController,
            hintText: 'Subcategory ID',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _createdByController,
            hintText: 'Created By User ID',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Create Meeting',
            onPressed: _save,
            isLoading: isSaving,
          ),
        ],
      ),
    );
  }
}
