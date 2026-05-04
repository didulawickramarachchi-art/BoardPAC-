import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<void> _showAddDialog() async {
    final userIdController = TextEditingController();
    final sequenceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Participant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(labelText: 'User ID'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sequenceController,
              decoration: const InputDecoration(labelText: 'Display Sequence'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(participantListProvider(widget.meetingId).notifier)
                  .addParticipant(
                    MeetingParticipantRequest(
                      meetingId: widget.meetingId,
                      userId: int.parse(userIdController.text.trim()),
                      displaySequence: sequenceController.text.trim().isEmpty
                          ? null
                          : int.parse(sequenceController.text.trim()),
                    ),
                  );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusDialog(int userId) async {
    final reasonController = TextEditingController();
    String status = 'ACCEPTED';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Update Participant Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: status,
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
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
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
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(
      participantListProvider(widget.meetingId),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Participants - ${widget.meetingTitle}')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: participantsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No participants found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final participant = items[index];
              return Card(
                child: ListTile(
                  title: Text(participant.username),
                  subtitle: Text(
                    'Status: ${participant.participantStatus}\n'
                    '${participant.statusReason ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showStatusDialog(participant.userId),
                  ),
                ),
              );
            },
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load participants: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
