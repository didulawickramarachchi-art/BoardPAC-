import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/access_control/presentation/access_validation_screen.dart';
import 'package:frontend/features/reports/presentation/report_home_screen.dart';
import 'package:frontend/features/settings/presentation/setting_home_screen.dart';

import '../../auth/provider/auth_provider.dart';
import '../../categories/presentation/category_list_screen.dart';
import '../../devices/presentation/device_list_screen.dart';
import '../../meetings/presentation/meeting_list_screen.dart';
import '../../privileges/presentation/privilege_list_screen.dart';
import '../../subcategories/presentation/subcategory_list_screen.dart';
import '../../users/presentation/user_list_screen.dart';
import '../provider/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const currentUserId = 1;
    final summaryAsync = ref.watch(dashboardSummaryProvider(currentUserId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    summaryAsync.when(
                      data: (summary) => GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.05,
                        children: [
                          _SummaryCard(
                            title: 'Meetings',
                            value: summary.totalMeetings.toString(),
                            icon: Icons.event,
                            iconColor: const Color(0xFFF4A51C),
                            iconBg: const Color(0xFFFFF3DC),
                            screen: const MeetingListScreen(),
                          ),
                          _SummaryCard(
                            title: 'Circulars',
                            value: summary.totalCirculars.toString(),
                            icon: Icons.mail_outline,
                            iconColor: const Color(0xFFE84393),
                            iconBg: const Color(0xFFFFE7F2),
                            screen: const MeetingListScreen(),
                          ),
                          _SummaryCard(
                            title: 'Pending Approvals',
                            value: summary.pendingApprovals.toString(),
                            icon: Icons.how_to_vote,
                            iconColor: const Color(0xFF3168F4),
                            iconBg: const Color(0xFFEAF0FF),
                            screen: const MeetingListScreen(),
                          ),
                          _SummaryCard(
                            title: 'Unread Papers',
                            value: summary.unreadPapers.toString(),
                            icon: Icons.picture_as_pdf,
                            iconColor: const Color(0xFFE74C3C),
                            iconBg: const Color(0xFFFFEAEA),
                            screen: const MeetingListScreen(),
                          ),
                          _SummaryCard(
                            title: 'Shared Comments',
                            value: summary.sharedComments.toString(),
                            icon: Icons.comment_outlined,
                            iconColor: const Color(0xFF20C997),
                            iconBg: const Color(0xFFE0F8F1),
                            screen: const MeetingListScreen(),
                          ),
                          _SummaryCard(
                            title: 'Shared Docs',
                            value: summary.sharedDocuments.toString(),
                            icon: Icons.share_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFF1EAFE),
                            screen: const CategoryListScreen(),
                          ),
                        ],
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          error.toString(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Upcoming Meetings',
                      style: TextStyle(
                        color: Color(0xFF00184A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    summaryAsync.when(
                      data: (summary) => _UpcomingMeetingCard(
                        title: summary.upcomingMeetingTitle ?? 'No upcoming meeting',
                        dateTimeText: summary.upcomingMeetingDateTime ?? 'No date available',
                        location: summary.upcomingMeetingLocation ?? 'No location',
                        daysText: summary.upcomingMeetingDaysText ?? '',
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Management',
                      style: TextStyle(
                        color: Color(0xFF00184A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _MenuGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final authState = ref.watch(authProvider);

    final userName = authState.username ?? 'Admin';
    final role = authState.role ?? 'User';
    final initials = _getInitials(userName);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF12275B),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'SLPA',
                    style: TextStyle(
                      color: Color(0xFF00184A),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLPA Board',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Management\nSystem',
                      style: TextStyle(
                        color: Color(0xFFFFB52E),
                        fontSize: 8,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB52E),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF00184A),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingText(),
                      style: const TextStyle(
                        color: Color(0xFFB9C4E2),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _RoleChip(role: role),
                  ],
                ),
              ),
              Container(
                width: 65,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF30467D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    Text(
                      now.day.toString(),
                      style: const TextStyle(
                        color: Color(0xFFFFB52E),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${_monthName(now.month)} ${now.year}\n${_weekDayName(now.weekday)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFC5CDE2),
                        fontSize: 9,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingMeetingCard extends StatelessWidget {
  final String title;
  final String dateTimeText;
  final String location;
  final String daysText;

  const _UpcomingMeetingCard({
    required this.title,
    required this.dateTimeText,
    required this.location,
    required this.daysText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MeetingListScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF233E8B),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (daysText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC88824),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  daysText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              '$dateTimeText · $location',
              style: const TextStyle(
                color: Color(0xFFD8E2FF),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: const Color(0xFFFFB52E)),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Color(0xFFFFB52E),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget screen;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF00184A),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7D8CB2),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MenuTileData('Users', Icons.people_outline, const UserListScreen()),
      _MenuTileData('Devices', Icons.devices_other_outlined, const DeviceListScreen()),
      _MenuTileData('Categories', Icons.category_outlined, const CategoryListScreen()),
      _MenuTileData('Subcategories', Icons.account_tree_outlined, const SubcategoryListScreen()),
      _MenuTileData('Privileges', Icons.admin_panel_settings_outlined, const PrivilegeListScreen()),
      _MenuTileData('Meetings', Icons.event_note_outlined, const MeetingListScreen()),
      _MenuTileData('Reports', Icons.bar_chart_outlined, const ReportHomeScreen()),
      _MenuTileData('Settings', Icons.settings_outlined, const SettingHomeScreen()),
      _MenuTileData('Access Control', Icons.verified_user_outlined, const AccessValidationScreen()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final item = tiles[index];

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item.screen),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: const Color(0xFF233E8B),
                  size: 23,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF00184A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuTileData {
  final String title;
  final IconData icon;
  final Widget screen;

  _MenuTileData(this.title, this.icon, this.screen);
}

String _greetingText() {
  final hour = DateTime.now().hour;

  if (hour < 12) return 'Good Morning,';
  if (hour < 17) return 'Good Afternoon,';
  return 'Good Evening,';
}

String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  return months[month - 1];
}

String _weekDayName(int day) {
  const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  return days[day - 1];
}

String _getInitials(String name) {
  final cleanName = name.trim();

  if (cleanName.isEmpty) return 'U';

  final parts = cleanName.split(RegExp(r'\s+'));

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}