import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/meeting_participant_request.dart';
import '../model/participant_status_request.dart';
import '../provider/meeting_provider.dart';

class ParticipantListScreen extends ConsumerStatefulWidget {
  final int meetingId;
  final String meetingTitle;

  const ParticipantListScreen({
    super.key,
    required this.meetingId,
    required this.meetingTitle,
  });

  @override
  ConsumerState<ParticipantListScreen> createState() =>
      _ParticipantListScreenState();
}

class _ParticipantListScreenState extends ConsumerState<ParticipantListScreen> {
  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  Future<void> _showAddDialog() async {
    final sequenceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int? selectedUserId;
    var isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Add Participant',
            style: TextStyle(color: darkBlue, fontWeight: FontWeight.w900),
          ),
          content: Consumer(
            builder: (context, dialogRef, _) {
              final usersAsync = dialogRef.watch(
                participantOptionsProvider(widget.meetingId),
              );

              return SizedBox(
                width: 360,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      usersAsync.when(
                        data: (users) {
                          final availableUsers = users.toList()
                            ..sort(
                              (a, b) => a.username.toLowerCase().compareTo(
                                b.username.toLowerCase(),
                              ),
                            );

                          if (availableUsers.isEmpty) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No eligible users are available.',
                                style: TextStyle(color: Color(0xFF7D8CB2)),
                              ),
                            );
                          }

                          return DropdownButtonFormField<int>(
                            initialValue: selectedUserId,
                            isExpanded: true,
                            decoration: _dialogInputDecoration('Select User'),
                            dropdownColor: Colors.white,
                            items: availableUsers.map((user) {
                              final fullName =
                                  '${user.firstName} ${user.lastName}'.trim();
                              final label = fullName.isEmpty
                                  ? user.username
                                  : '$fullName (${user.username})';
                              return DropdownMenuItem<int>(
                                value: user.id,
                                enabled: !user.isParticipant && user.isEligible,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user.isParticipant) ...[
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Already added',
                                        style: TextStyle(
                                          color: Color(0xFF20A67A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ] else if (!user.isEligible) ...[
                                      const SizedBox(width: 8),
                                      const Text(
                                        'No access',
                                        style: TextStyle(
                                          color: Color(0xFFC88824),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            validator: (value) =>
                                value == null ? 'Please select a user' : null,
                            onChanged: isSubmitting
                                ? null
                                : (value) => selectedUserId = value,
                          );
                        },
                        loading: () =>
                            const LinearProgressIndicator(color: gold),
                        error: (error, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unable to load users.',
                              style: TextStyle(color: Colors.red),
                            ),
                            TextButton.icon(
                              onPressed: () => dialogRef.invalidate(
                                participantOptionsProvider(widget.meetingId),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DialogTextField(
                        controller: sequenceController,
                        label: 'Display Sequence (optional)',
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isNotEmpty && int.tryParse(text) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF7D8CB2)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryBlue.withValues(alpha: 0.65),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false) ||
                          selectedUserId == null) {
                        return;
                      }

                      FocusScope.of(dialogContext).unfocus();
                      setDialogState(() => isSubmitting = true);

                      final sequenceText = sequenceController.text.trim();

                      try {
                        await ref
                            .read(
                              participantListProvider(
                                widget.meetingId,
                              ).notifier,
                            )
                            .addParticipant(
                              MeetingParticipantRequest(
                                meetingId: widget.meetingId,
                                userId: selectedUserId!,
                                displaySequence: sequenceText.isEmpty
                                    ? null
                                    : int.parse(sequenceText),
                              ),
                            );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to add participant: $error',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );

    // showDialog completes as soon as the route is popped, before its reverse
    // animation and IME teardown have necessarily finished. Disposing a
    // controller while the Android keyboard still references its field can
    // stall the platform input channel.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    sequenceController.dispose();
  }

  Future<void> _showStatusDialog(int userId) async {
    final reasonController = TextEditingController();
    String status = 'ACCEPTED';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Update Status',
            style: TextStyle(color: darkBlue, fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: _dialogInputDecoration('Participant Status'),
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primaryBlue,
                ),
                items: const [
                  DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                  DropdownMenuItem(value: 'ACCEPTED', child: Text('Accepted')),
                  DropdownMenuItem(value: 'DECLINED', child: Text('Declined')),
                  DropdownMenuItem(
                    value: 'TENTATIVE',
                    child: Text('Tentative'),
                  ),
                  DropdownMenuItem(value: 'CONCALL', child: Text('Concall')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setLocalState(() => status = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              _DialogTextField(
                controller: reasonController,
                label: 'Reason',
                keyboardType: TextInputType.text,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF7D8CB2)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                await ref
                    .read(participantListProvider(widget.meetingId).notifier)
                    .updateStatus(
                      ParticipantStatusRequest(
                        meetingId: widget.meetingId,
                        userId: userId,
                        participantStatus: status,
                        statusReason: reasonController.text.trim(),
                      ),
                    );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(
      participantListProvider(widget.meetingId),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Participants',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: gold,
        foregroundColor: darkBlue,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: _showAddDialog,
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: participantsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No participants found');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _MeetingHeaderCard(meetingTitle: widget.meetingTitle);
              }

              final participant = items[index - 1];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: primaryBlue,
                          size: 27,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participant.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: darkBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 8),

                            _StatusChip(status: participant.participantStatus),

                            if ((participant.statusReason ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 15,
                                    color: Color(0xFF7D8CB2),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      participant.statusReason ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF7D8CB2),
                                        fontSize: 12,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: primaryBlue.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: primaryBlue,
                          size: 21,
                        ),
                        onPressed: () => _showStatusDialog(participant.userId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Failed to load participants: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        loading: () => const AppLoading(),
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String label) {
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
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
    );
  }
}

class _MeetingHeaderCard extends StatelessWidget {
  final String meetingTitle;

  const _MeetingHeaderCard({required this.meetingTitle});

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
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: darkBlue,
              size: 31,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meeting Participants',
                  style: TextStyle(
                    color: Color(0xFFB9C4E2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  meetingTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Manage attendee status and responses',
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

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final lowerStatus = status.toLowerCase();

    Color bgColor;
    Color textColor;

    if (lowerStatus.contains('accepted')) {
      bgColor = const Color(0xFFE0F8F1);
      textColor = const Color(0xFF20A67A);
    } else if (lowerStatus.contains('pending') ||
        lowerStatus.contains('tentative') ||
        lowerStatus.contains('concall')) {
      bgColor = const Color(0xFFFFF3DC);
      textColor = const Color(0xFFC88824);
    } else if (lowerStatus.contains('declined')) {
      bgColor = const Color(0xFFFFEAEA);
      textColor = const Color(0xFFE74C3C);
    } else {
      bgColor = const Color(0xFFEAF0FF);
      textColor = const Color(0xFF233E8B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const _DialogTextField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.number,
    this.textInputAction,
    this.validator,
  });

  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: validator,
      decoration: InputDecoration(
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
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
      ),
    );
  }
}
