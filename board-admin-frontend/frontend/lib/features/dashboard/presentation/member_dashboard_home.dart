import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../meetings/model/meeting_model.dart';
import '../../favorites/presentation/member_library_screen.dart';
import '../../meetings/presentation/meeting_detail_screen.dart';
import '../../meetings/presentation/member_calendar_screen.dart';
import '../../meetings/provider/meeting_provider.dart';
import '../../notifications/model/notification_model.dart';
import '../../notifications/provider/notification_provider.dart';
import '../../papers/model/paper_model.dart';
import '../../papers/presentation/paper_detail_screen.dart';
import '../../papers/provider/paper_provider.dart';
import '../../users/presentation/profile_picture_screen.dart';
import '../model/dashboard_summary_model.dart';
import '../provider/dashboard_provider.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../reports/presentation/personal_activity_screen.dart';

class MemberDashboardHome extends ConsumerStatefulWidget {
  final int userId;
  final String role;
  final AsyncValue<DashboardSummaryModel> summary;
  final AsyncValue<List<NotificationModel>> notifications;

  const MemberDashboardHome({
    super.key,
    required this.userId,
    required this.role,
    required this.summary,
    required this.notifications,
  });

  @override
  ConsumerState<MemberDashboardHome> createState() =>
      _MemberDashboardHomeState();
}

class _MemberDashboardHomeState extends ConsumerState<MemberDashboardHome> {
  static const _boardPreferencePrefix = 'member_dashboard_board_';
  String _selectedBoard = 'All';
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _restoreBoardSelection();
  }

  Future<void> _restoreBoardSelection() async {
    final stored = await SecureStorageService().read(
      '$_boardPreferencePrefix${widget.userId}',
    );
    if (stored != null && stored.trim().isNotEmpty && mounted) {
      setState(() => _selectedBoard = stored.trim());
    }
  }

  Future<void> _selectBoard(String value) async {
    setState(() => _selectedBoard = value);
    await SecureStorageService().write(
      '$_boardPreferencePrefix${widget.userId}',
      value,
    );
  }

  Future<void> _refresh() async {
    await ref.read(meetingListProvider.notifier).loadMeetings();
    ref.invalidate(dashboardSummaryProvider(widget.userId));
    ref.invalidate(notificationListProvider(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final meetingsAsync = ref.watch(meetingListProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BoardPAC', style: TextStyle(fontWeight: FontWeight.w900)),
            Text(
              'Member workspace',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My activity',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonalActivityScreen()),
            ),
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Search board content',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Favorites and last viewed',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemberLibraryScreen()),
            ),
            icon: const Icon(Icons.collections_bookmark_outlined),
          ),
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'My profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePictureScreen()),
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: meetingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DashboardError(
          message: ApiErrorMessage.from(error),
          onRetry: _refresh,
        ),
        data: (meetings) {
          final boards = _boardNames(meetings);
          if (!boards.contains(_selectedBoard)) _selectedBoard = 'All';
          final filtered = _selectedBoard == 'All'
              ? meetings
              : meetings.where((m) => _boardName(m) == _selectedBoard).toList();
          final scheduled = [...filtered]
            ..sort((a, b) => a.meetingDateTime.compareTo(b.meetingDateTime));
          final unreadByBoard = _unreadCountsByBoard(
            meetings,
            widget.notifications.valueOrNull ?? const <NotificationModel>[],
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              children: [
                _WelcomeCard(summary: widget.summary),
                const SizedBox(height: 20),
                const _SectionHeading(
                  title: 'Meetings',
                  subtitle: 'Your accessible boards and meeting packs',
                ),
                const SizedBox(height: 10),
                _BoardSelector(
                  boards: boards,
                  selected: _selectedBoard,
                  unreadCounts: unreadByBoard,
                  onSelected: _selectBoard,
                ),
                const SizedBox(height: 12),
                _MeetingStrip(meetings: scheduled),
                const SizedBox(height: 22),
                _CalendarPanel(
                  visibleMonth: _visibleMonth,
                  selectedDay: _selectedDay,
                  meetings: filtered,
                  onPrevious: () => setState(
                    () => _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                    ),
                  ),
                  onNext: () => setState(
                    () => _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + 1,
                    ),
                  ),
                  onSelectDay: (day) => setState(() => _selectedDay = day),
                  onOpenCalendar: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MemberCalendarScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _RecentDocuments(meetings: filtered),
                const SizedBox(height: 22),
                _MemberWhatsNew(
                  summary: widget.summary,
                  notifications: widget.notifications,
                  meetingIds: meetings.map((m) => m.id).toSet(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final AsyncValue<DashboardSummaryModel> summary;
  const _WelcomeCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071C4D), Color(0xFF244B9B)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your board workspace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Meetings, documents and decisions in one place.',
                  style: TextStyle(color: Color(0xFFDCE6FF)),
                ),
              ],
            ),
          ),
          summary.maybeWhen(
            data: (value) =>
                _CountBadge(count: value.pendingApprovals, label: 'Pending'),
            orElse: () => const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final String label;
  const _CountBadge({required this.count, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Color(0xFFFFC04D),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const _SectionHeading({this.title = '', this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF071C4D),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle case final subtitle?)
              Text(subtitle, style: const TextStyle(color: Color(0xFF69758C))),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class _BoardSelector extends StatelessWidget {
  final List<String> boards;
  final String selected;
  final Map<String, int> unreadCounts;
  final ValueChanged<String> onSelected;
  const _BoardSelector({
    required this.boards,
    required this.selected,
    required this.unreadCounts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: boards
          .map(
            (board) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(board),
                    if ((unreadCounts[board] ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: board == selected
                              ? Colors.white
                              : const Color(0xFF244B9B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${unreadCounts[board]}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: board == selected
                                ? const Color(0xFF244B9B)
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: board == selected,
                onSelected: (_) => onSelected(board),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _MeetingStrip extends StatelessWidget {
  final List<MeetingModel> meetings;
  const _MeetingStrip({required this.meetings});

  @override
  Widget build(BuildContext context) {
    if (meetings.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.event_busy_outlined,
        message: 'No meetings are available for this board.',
      );
    }
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: meetings.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final meeting = meetings[index];
          final date = DateTime.tryParse(meeting.meetingDateTime)?.toLocal();
          return SizedBox(
            width: 285,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeetingDetailScreen(meeting: meeting),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _boardName(meeting),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF244B9B),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _StatusPill(status: meeting.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        meeting.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF071C4D),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        date == null
                            ? meeting.meetingDateTime
                            : '${_shortDate(date)}  ${_time(date)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meeting.location?.trim().isNotEmpty == true
                            ? meeting.location!
                            : 'Location not provided',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF69758C)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFC04D).withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.isEmpty ? 'Scheduled' : status,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _CalendarPanel extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final List<MeetingModel> meetings;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onOpenCalendar;

  const _CalendarPanel({
    required this.visibleMonth,
    required this.selectedDay,
    required this.meetings,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectDay,
    required this.onOpenCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final selectedMeetings = meetings.where((meeting) {
      final date = DateTime.tryParse(meeting.meetingDateTime)?.toLocal();
      return date != null && _sameDay(date, selectedDay);
    }).toList();
    final firstOffset =
        DateTime(visibleMonth.year, visibleMonth.month, 1).weekday - 1;
    final dayCount = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final markedDays = meetings
        .map((m) => DateTime.tryParse(m.meetingDateTime)?.toLocal())
        .whereType<DateTime>()
        .where(
          (d) => d.year == visibleMonth.year && d.month == visibleMonth.month,
        )
        .map((d) => d.day)
        .toSet();
    return Column(
      children: [
        _SectionHeading(
          title: 'Calendar',
          subtitle: 'Select a marked date to view its schedule',
          trailing: TextButton(
            onPressed: onOpenCalendar,
            child: const Text('Full calendar'),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final calendar = Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: onPrevious,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          onPressed: onNext,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    Row(
                      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                          .map(
                            (d) => Expanded(
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF69758C),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: firstOffset + dayCount,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                          ),
                      itemBuilder: (_, index) {
                        final day = index - firstOffset + 1;
                        if (day < 1) return const SizedBox.shrink();
                        final date = DateTime(
                          visibleMonth.year,
                          visibleMonth.month,
                          day,
                        );
                        final selected = _sameDay(date, selectedDay);
                        final marked = markedDays.contains(day);
                        return InkWell(
                          onTap: () => onSelectDay(date),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF244B9B)
                                  : marked
                                  ? const Color(
                                      0xFFFFC04D,
                                    ).withValues(alpha: 0.28)
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: selected ? Colors.white : null,
                                fontWeight: marked
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
            final schedule = _DaySchedule(
              day: selectedDay,
              meetings: selectedMeetings,
            );
            if (constraints.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: calendar),
                  const SizedBox(width: 12),
                  Expanded(child: schedule),
                ],
              );
            }
            return Column(
              children: [calendar, const SizedBox(height: 12), schedule],
            );
          },
        ),
      ],
    );
  }
}

class _DaySchedule extends StatelessWidget {
  final DateTime day;
  final List<MeetingModel> meetings;
  const _DaySchedule({required this.day, required this.meetings});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sameDay(day, DateTime.now()) ? 'Today' : _shortDate(day),
            style: const TextStyle(
              color: Color(0xFF071C4D),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (meetings.isEmpty)
            const _EmptyPanel(
              icon: Icons.event_available_outlined,
              message: 'No meetings scheduled for this date.',
            )
          else
            ...meetings.map(
              (meeting) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(
                    _time(DateTime.parse(meeting.meetingDateTime).toLocal()),
                  ),
                ),
                title: Text(
                  meeting.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(meeting.location ?? _boardName(meeting)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeetingDetailScreen(meeting: meeting),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _RecentDocuments extends ConsumerWidget {
  final List<MeetingModel> meetings;
  const _RecentDocuments({required this.meetings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitedMeetings = meetings.take(6).toList();
    final paperStates = limitedMeetings
        .map(
          (meeting) => (
            meeting: meeting,
            papers: ref.watch(paperListProvider(meeting.id)),
          ),
        )
        .toList();
    final loading = paperStates.any((entry) => entry.papers.isLoading);
    final documents = <({MeetingModel meeting, PaperModel paper})>[];
    for (final entry in paperStates) {
      for (final paper in entry.papers.valueOrNull ?? const <PaperModel>[]) {
        documents.add((meeting: entry.meeting, paper: paper));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Shared documents',
          subtitle: 'Recent papers from your accessible meetings',
        ),
        const SizedBox(height: 10),
        if (loading && documents.isEmpty)
          const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (documents.isEmpty)
          const _EmptyPanel(
            icon: Icons.folder_shared_outlined,
            message: 'No shared documents are available yet.',
          )
        else
          Card(
            child: Column(
              children: documents.take(5).map((entry) {
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.description_outlined),
                  ),
                  title: Text(
                    entry.paper.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${entry.meeting.title} - Version ${entry.paper.versionNumber ?? 1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaperDetailScreen(paper: entry.paper),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _MemberWhatsNew extends StatelessWidget {
  final AsyncValue<DashboardSummaryModel> summary;
  final AsyncValue<List<NotificationModel>> notifications;
  final Set<int> meetingIds;
  const _MemberWhatsNew({
    required this.summary,
    required this.notifications,
    required this.meetingIds,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: "What's new",
          subtitle: 'Updates requiring your attention',
        ),
        const SizedBox(height: 10),
        summary.maybeWhen(
          data: (value) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                icon: Icons.approval_outlined,
                value: value.pendingApprovals,
                label: 'Pending approvals',
              ),
              _MetricTile(
                icon: Icons.mark_email_unread_outlined,
                value: value.unreadPapers,
                label: 'Unread papers',
              ),
              _MetricTile(
                icon: Icons.forum_outlined,
                value: value.sharedComments,
                label: 'Paper comments',
              ),
              _MetricTile(
                icon: Icons.folder_shared_outlined,
                value: value.sharedDocuments,
                label: 'Shared docs',
              ),
            ],
          ),
          orElse: () => const LinearProgressIndicator(),
        ),
        const SizedBox(height: 12),
        notifications.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) {
            final visible = items
                .where(
                  (item) =>
                      item.relatedMeetingId == null ||
                      meetingIds.contains(item.relatedMeetingId),
                )
                .take(4)
                .toList();
            if (visible.isEmpty) {
              return const _EmptyPanel(
                icon: Icons.notifications_none_rounded,
                message: 'You are up to date.',
              );
            }
            return Card(
              child: Column(
                children: visible
                    .map(
                      (item) => ListTile(
                        leading: Icon(
                          item.read
                              ? Icons.notifications_none_rounded
                              : Icons.notifications_active_outlined,
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: item.read
                                ? FontWeight.w600
                                : FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 165,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E5EF)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF244B9B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF69758C), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyPanel({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0E5EF)),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF69758C)),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF69758C)),
        ),
      ],
    ),
  );
}

class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

List<String> _boardNames(List<MeetingModel> meetings) {
  final names = meetings.map(_boardName).toSet().toList()..sort();
  return ['All', ...names];
}

Map<String, int> _unreadCountsByBoard(
  List<MeetingModel> meetings,
  List<NotificationModel> notifications,
) {
  final boardByMeetingId = {
    for (final meeting in meetings) meeting.id: _boardName(meeting),
  };
  final counts = <String, int>{'All': 0};
  for (final notification in notifications) {
    if (notification.read) continue;
    final meetingId = notification.relatedMeetingId;
    if (meetingId == null) continue;
    final board = boardByMeetingId[meetingId];
    if (board == null) continue;
    counts['All'] = (counts['All'] ?? 0) + 1;
    counts[board] = (counts[board] ?? 0) + 1;
  }
  return counts;
}

String _boardName(MeetingModel meeting) {
  final category = meeting.categoryName?.trim();
  if (category != null && category.isNotEmpty) return category;
  final subcategory = meeting.subcategoryName?.trim();
  if (subcategory != null && subcategory.isNotEmpty) return subcategory;
  return 'General';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _time(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
}

String _shortDate(DateTime value) =>
    '${value.day} ${_monthName(value.month).substring(0, 3)} ${value.year}';

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
