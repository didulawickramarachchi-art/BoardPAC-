import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/meeting_model.dart';
import '../provider/meeting_provider.dart';
import 'meeting_detail_screen.dart';
import 'reminder_settings_screen.dart';

/// Compact member calendar used on the dashboard. It deliberately keeps the
/// month and the selected day's meetings together, matching the mental model
/// of existing BoardPAC users while using the current app theme.
class MemberDashboardCalendar extends StatefulWidget {
  final List<MeetingModel> meetings;
  final bool loading;
  final VoidCallback onOpenCalendar;

  const MemberDashboardCalendar({
    super.key,
    required this.meetings,
    required this.loading,
    required this.onOpenCalendar,
  });

  @override
  State<MemberDashboardCalendar> createState() =>
      _MemberDashboardCalendarState();
}

class _MemberDashboardCalendarState extends State<MemberDashboardCalendar> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final dayMeetings = widget.meetings.where((meeting) {
      final date = DateTime.tryParse(meeting.meetingDateTime)?.toLocal();
      return date != null && _sameDay(date, _selectedDay);
    }).toList()..sort((a, b) => a.meetingDateTime.compareTo(b.meetingDateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Meeting Calendar',
                style: TextStyle(
                  color: AppColors.navyDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: widget.onOpenCalendar,
              icon: const Icon(Icons.open_in_full_rounded, size: 16),
              label: const Text('Open calendar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 680;
              final calendar = _DashboardMonth(
                visibleMonth: _visibleMonth,
                selectedDay: _selectedDay,
                meetings: widget.meetings,
                onPrevious: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month - 1,
                  );
                }),
                onNext: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month + 1,
                  );
                }),
                onSelected: (day) => setState(() => _selectedDay = day),
              );
              final schedule = _DashboardDaySchedule(
                selectedDay: _selectedDay,
                meetings: dayMeetings,
                loading: widget.loading,
              );
              if (wide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: calendar),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 5, child: schedule),
                    ],
                  ),
                );
              }
              return Column(
                children: [calendar, const Divider(height: 1), schedule],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardMonth extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final List<MeetingModel> meetings;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelected;

  const _DashboardMonth({
    required this.visibleMonth,
    required this.selectedDay,
    required this.meetings,
    required this.onPrevious,
    required this.onNext,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final offset =
        DateTime(visibleMonth.year, visibleMonth.month, 1).weekday - 1;
    final days = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final marked = meetings
        .map((meeting) => DateTime.tryParse(meeting.meetingDateTime)?.toLocal())
        .whereType<DateTime>()
        .where(
          (date) =>
              date.year == visibleMonth.year &&
              date.month == visibleMonth.month,
        )
        .map((date) => date.day)
        .toSet();
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navyDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Row(
            children: [
              for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offset + days,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (_, index) {
              final day = index - offset + 1;
              if (day < 1) return const SizedBox.shrink();
              final date = DateTime(visibleMonth.year, visibleMonth.month, day);
              final selected = _sameDay(date, selectedDay);
              final today = _isToday(date);
              final hasMeetings = marked.contains(day);
              return Semantics(
                button: true,
                selected: selected,
                label:
                    '${_monthName(date.month)} $day'
                    '${hasMeetings ? ', has meetings' : ''}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelected(date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hasMeetings
                          ? AppColors.danger
                          : selected
                          ? AppColors.navy
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: today && !selected
                          ? Border.all(color: AppColors.gold, width: 1.5)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            color: selected || hasMeetings
                                ? Colors.white
                                : AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (hasMeetings)
                          Positioned(
                            bottom: 3,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardDaySchedule extends StatelessWidget {
  final DateTime selectedDay;
  final List<MeetingModel> meetings;
  final bool loading;

  const _DashboardDaySchedule({
    required this.selectedDay,
    required this.meetings,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted.withValues(alpha: 0.55),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 190),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isToday(selectedDay)
                ? 'Today'
                : '${_monthName(selectedDay.month)} ${selectedDay.day}',
            style: const TextStyle(
              color: AppColors.navyDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            meetings.isEmpty
                ? 'Your schedule is clear'
                : '${meetings.length} meeting${meetings.length == 1 ? '' : 's'} scheduled',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 13),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (meetings.isEmpty)
            const _DashboardCalendarEmpty()
          else
            for (final meeting in meetings)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DashboardMeetingRow(meeting: meeting),
              ),
        ],
      ),
    );
  }
}

class _DashboardCalendarEmpty extends StatelessWidget {
  const _DashboardCalendarEmpty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text(
            'Select a marked date to see its meetings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _DashboardMeetingRow extends StatelessWidget {
  final MeetingModel meeting;
  const _DashboardMeetingRow({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(meeting.meetingDateTime)?.toLocal();
    final time = date == null
        ? 'Scheduled'
        : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MeetingDetailScreen(meeting: meeting),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Container(
                width: 43,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  time,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navyDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navyDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meeting.location?.trim().isNotEmpty == true
                          ? meeting.location!
                          : meeting.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class MemberCalendarScreen extends ConsumerStatefulWidget {
  const MemberCalendarScreen({super.key});

  @override
  ConsumerState<MemberCalendarScreen> createState() =>
      _MemberCalendarScreenState();
}

class _MemberCalendarScreenState extends ConsumerState<MemberCalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final meetings = ref.watch(meetingListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Calendar'),
        actions: [
          IconButton(
            tooltip: 'Reminder settings',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()),
            ),
          ),
        ],
      ),
      body: meetings.when(
        loading: () => const AppLoading(),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(meetingListProvider.notifier).loadMeetings(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _CalendarCard(
                visibleMonth: _visibleMonth,
                selectedDay: _selectedDay,
                meetings: items,
                onPrevious: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month - 1,
                  );
                }),
                onNext: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month + 1,
                  );
                }),
                onSelected: (day) => setState(() => _selectedDay = day),
              ),
              const SizedBox(height: 22),
              Text(
                _isToday(_selectedDay)
                    ? "Today's schedule"
                    : '${_monthName(_selectedDay.month)} ${_selectedDay.day}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.navyDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ..._schedule(context, items),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _schedule(BuildContext context, List<MeetingModel> meetings) {
    final selected = meetings.where((meeting) {
      final date = DateTime.tryParse(meeting.meetingDateTime)?.toLocal();
      return date != null && _sameDay(date, _selectedDay);
    }).toList()..sort((a, b) => a.meetingDateTime.compareTo(b.meetingDateTime));
    if (selected.isEmpty) {
      return const [
        SizedBox(
          height: 180,
          child: AppEmptyState(message: 'No meetings on this date'),
        ),
      ];
    }
    return selected
        .map(
          (meeting) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MeetingTile(
              meeting: meeting,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MeetingDetailScreen(meeting: meeting),
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final List<MeetingModel> meetings;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelected;

  const _CalendarCard({
    required this.visibleMonth,
    required this.selectedDay,
    required this.meetings,
    required this.onPrevious,
    required this.onNext,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    ).weekday;
    final dayCount = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final markedDays = meetings
        .map((meeting) => DateTime.tryParse(meeting.meetingDateTime)?.toLocal())
        .whereType<DateTime>()
        .where(
          (date) =>
              date.year == visibleMonth.year &&
              date.month == visibleMonth.month,
        )
        .map((date) => date.day)
        .toSet();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navyDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: firstWeekday - 1 + dayCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, index) {
              final day = index - firstWeekday + 2;
              if (day < 1) return const SizedBox.shrink();
              final date = DateTime(visibleMonth.year, visibleMonth.month, day);
              final selected = _sameDay(date, selectedDay);
              final marked = markedDays.contains(day);
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: marked
                        ? AppColors.danger
                        : selected
                        ? AppColors.navy
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: selected || marked
                              ? Colors.white
                              : AppColors.text,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: marked ? Colors.white : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback onTap;
  const _MeetingTile({required this.meeting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(meeting.meetingDateTime)?.toLocal();
    final time = date == null
        ? meeting.meetingDateTime
        : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            meeting.type == 'CIRCULAR'
                ? Icons.campaign_outlined
                : Icons.event_note_outlined,
          ),
        ),
        title: Text(
          meeting.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('$time  •  ${meeting.location ?? 'No location'}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isToday(DateTime value) => _sameDay(value, DateTime.now());

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
