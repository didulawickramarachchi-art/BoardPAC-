import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../../agendas/presentation/agenda_section_screen.dart';
import '../../papers/presentation/paper_list_screen.dart';
import '../provider/meeting_provider.dart';
import 'meeting_form_screen.dart';
import 'participant_list_screen.dart';

class MeetingListScreen extends ConsumerWidget {
  const MeetingListScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingListProvider);
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');

    if (!access.canViewMeetings) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text('You do not have access to meetings.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Meetings & Circulars',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: access.canManageMeetings
          ? FloatingActionButton(
              backgroundColor: gold,
              foregroundColor: darkBlue,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MeetingFormScreen()),
                );
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: meetingsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No meetings found');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final meeting = items[index];

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    _showMeetingOptions(context, meeting, access);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            meeting.type == 'CIRCULAR'
                                ? Icons.campaign_outlined
                                : Icons.event_note_outlined,
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
                                meeting.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: darkBlue,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 7),

                              Row(
                                children: [
                                  _SmallChip(
                                    text: meeting.type,
                                    bgColor: gold.withOpacity(0.16),
                                    textColor: darkBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  _StatusChip(status: meeting.status),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 15,
                                    color: Color(0xFF7D8CB2),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      meeting.meetingDateTime,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF7D8CB2),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if ((meeting.subcategoryName ?? '').isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_tree_outlined,
                                      size: 15,
                                      color: Color(0xFF7D8CB2),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        meeting.subcategoryName ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF7D8CB2),
                                          fontSize: 12,
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

                        if (access.canManageMeetings)
                          PopupMenuButton<String>(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            icon: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.more_vert_rounded,
                                color: primaryBlue,
                                size: 22,
                              ),
                            ),
                            onSelected: (value) async {
                              final notifier =
                                  ref.read(meetingListProvider.notifier);

                              if (value == 'open') {
                                await notifier.openMeeting(meeting.id);
                              }

                              if (value == 'close') {
                                await notifier.closeMeeting(meeting.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'open',
                                child: _PopupItem(
                                  icon: Icons.lock_open_outlined,
                                  text: 'Open',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'close',
                                child: _PopupItem(
                                  icon: Icons.lock_outline,
                                  text: 'Close',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
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
              'Failed to load meetings: $error',
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

  static void _showMeetingOptions(
    BuildContext context,
    dynamic meeting,
    RoleAccess access,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DBEA),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              if (access.canManageMeetings)
                _BottomSheetTile(
                  icon: Icons.group_outlined,
                  title: 'Participants',
                  subtitle: 'View and manage meeting participants',
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

              if (access.canManageMeetings)
                _BottomSheetTile(
                  icon: Icons.view_list_outlined,
                  title: 'Agenda Sections',
                  subtitle: 'Manage agenda items and sections',
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

              _BottomSheetTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Papers',
                subtitle: 'View papers attached to this meeting',
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

    if (lowerStatus.contains('open') ||
        lowerStatus.contains('active') ||
        lowerStatus.contains('approved')) {
      bgColor = const Color(0xFFE0F8F1);
      textColor = const Color(0xFF20A67A);
    } else if (lowerStatus.contains('pending')) {
      bgColor = const Color(0xFFFFF3DC);
      textColor = const Color(0xFFC88824);
    } else if (lowerStatus.contains('close') ||
        lowerStatus.contains('inactive')) {
      bgColor = const Color(0xFFFFEAEA);
      textColor = const Color(0xFFE74C3C);
    } else {
      bgColor = const Color(0xFFEAF0FF);
      textColor = const Color(0xFF233E8B);
    }

    return _SmallChip(
      text: status,
      bgColor: bgColor,
      textColor: textColor,
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _SmallChip({
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PopupItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Color(0xFF12275B)),
        SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Color(0xFF00184A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BottomSheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: primaryBlue, size: 23),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: darkBlue,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF7D8CB2),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9AA6C5),
      ),
      onTap: onTap,
    );
  }
}
