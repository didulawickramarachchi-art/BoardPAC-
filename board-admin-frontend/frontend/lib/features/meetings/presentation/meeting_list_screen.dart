import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../agendas/presentation/agenda_section_screen.dart';
import '../../papers/presentation/paper_list_screen.dart';
import '../provider/meeting_provider.dart';
import 'meeting_form_screen.dart';
import 'participant_list_screen.dart';

class MeetingListScreen extends ConsumerWidget {
  const MeetingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meetings & Circulars')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MeetingFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: meetingsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No meetings found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final meeting = items[index];

              return Card(
                child: ListTile(
                  title: Text(meeting.title),
                  subtitle: Text(
                    '${meeting.type} • ${meeting.status}\n'
                    '${meeting.meetingDateTime}\n'
                    '${meeting.subcategoryName ?? ''}',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.group_outlined),
                              title: const Text('Participants'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ParticipantListScreen(
                                      meetingId: meeting.id,
                                      meetingTitle: meeting.title,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.view_list_outlined),
                              title: const Text('Agenda Sections'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AgendaSectionScreen(
                                      meetingId: meeting.id,
                                      meetingTitle: meeting.title,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf_outlined,
                              ),
                              title: const Text('Papers'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaperListScreen(
                                      meetingId: meeting.id,
                                      meetingTitle: meeting.title,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final notifier = ref.read(meetingListProvider.notifier);
                      if (value == 'open')
                        await notifier.openMeeting(meeting.id);
                      if (value == 'close')
                        await notifier.closeMeeting(meeting.id);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'open', child: Text('Open')),
                      PopupMenuItem(value: 'close', child: Text('Close')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load meetings: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
