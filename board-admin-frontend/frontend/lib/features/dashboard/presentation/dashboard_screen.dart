import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/access_control/presentation/access_validation_screen.dart';
import 'package:frontend/features/reports/presentation/report_home_screen.dart';
import 'package:frontend/features/settings/presentation/setting_home_screen.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../auth/provider/auth_provider.dart';
import '../../categories/presentation/category_list_screen.dart';
import '../../devices/presentation/device_list_screen.dart';
import '../../meetings/presentation/meeting_list_screen.dart';
import '../../papers/presentation/paper_list_screen.dart';
import '../../privileges/presentation/privilege_list_screen.dart';
import '../../subcategories/presentation/subcategory_list_screen.dart';
import '../../users/presentation/user_list_screen.dart';
import '../../users/presentation/profile_picture_screen.dart';
import '../../users/provider/user_provider.dart';
import '../model/dashboard_summary_model.dart';
import '../provider/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color cardBlue = Color(0xFF233E8B);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState.userId ?? 1;
    final role = authState.role ?? 'User';
    final config = _RoleDashboardConfig.forRole(role);
    final summaryAsync = ref.watch(dashboardSummaryProvider(currentUserId));

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: 18,
                  bottom: 24 + MediaQuery.paddingOf(context).bottom,
                ),
                child: ResponsivePage(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoleOverview(config: config),

                    const SizedBox(height: 16),

                    summaryAsync.when(
                      data: (summary) => _SummaryGrid(
                        cards: _summaryCardsForRole(summary, config),
                      ),

                      loading: () => const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                      error: (error, _) => _ErrorBox(message: error.toString()),
                    ),

                    const SizedBox(height: 24),

                    const _SectionTitle(title: 'Upcoming Meeting'),

                    const SizedBox(height: 10),

                    summaryAsync.when(
                      data: (summary) => _UpcomingMeetingCard(
                        currentUserId: currentUserId,
                        title:
                            summary.upcomingMeetingTitle ??
                            'No upcoming meeting',
                        dateTimeText:
                            summary.upcomingMeetingDateTime ??
                            'No date available',
                        location:
                            summary.upcomingMeetingLocation ?? 'No location',
                        daysText: summary.upcomingMeetingDaysText ?? '',
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    _SectionTitle(title: config.menuTitle),

                    const SizedBox(height: 10),

                    _MenuGrid(
                      tiles: config.tiles,
                      currentUserId: currentUserId,
                    ),
                  ],
                  ),
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

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final authState = ref.watch(authProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final userName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!
        : authState.username ?? 'User';
    final role = authState.role ?? 'User';
    final initials = _getInitials(userName);
    final profilePictureUrl = currentUser?.profilePictureUrl;
    final profilePicture = profilePictureUrl?.trim().isNotEmpty == true
        ? ref.watch(
            profilePictureProvider((
              userId: currentUser!.id,
              url: profilePictureUrl!.trim(),
            )),
          )
        : null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        22,
      ),
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/slpa_logo.png',
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLPA Board',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    Text(
                      'Management System',
                      style: TextStyle(
                        color: gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();

                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfilePictureScreen(),
                    ),
                  );
                  if (updated == true) {
                    ref.invalidate(currentUserProvider);
                    ref.invalidate(profilePictureProvider);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: gold,
                      child: ClipOval(
                        child: SizedBox.square(
                          dimension: 46,
                          child: profilePicture?.when(
                                data: (bytes) => Image.memory(
                                  bytes,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (_, error, _) {
                                    debugPrint(
                                      'Could not decode profile picture: $error',
                                    );
                                    return _ProfileInitials(
                                      initials: initials,
                                    );
                                  },
                                ),
                                loading: () => const Center(
                                  child: SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                error: (error, _) {
                                  debugPrint(
                                    'Could not load profile picture from '
                                    '$profilePictureUrl: $error',
                                  );
                                  return _ProfileInitials(initials: initials);
                                },
                              ) ??
                              _ProfileInitials(initials: initials),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E95A3),
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryBlue, width: 2),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _RoleChip(role: role),
                  ],
                ),
              ),

              Container(
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: Column(
                  children: [
                    Text(
                      now.day.toString(),
                      style: const TextStyle(
                        color: gold,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    Text(
                      '${_monthName(now.month)} ${now.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    Text(
                      _weekDayName(now.weekday),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFC5CDE2),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
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

class _ProfileInitials extends StatelessWidget {
  final String initials;

  const _ProfileInitials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _Header.gold,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: _Header.darkBlue,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00184A),
        fontSize: 17,
        fontWeight: FontWeight.w900,
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

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00184A),
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7D8CB2),
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<_SummaryCard> cards;

  const _SummaryGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsiveColumnCount(
          constraints.maxWidth,
          compact: constraints.maxWidth < 380 ? 1 : 2,
          medium: 3,
          expanded: 4,
          large: 4,
        );
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 2.3 : 1.18,
          children: cards,
        );
      },
    );
  }
}

class _RoleOverview extends StatelessWidget {
  final _RoleDashboardConfig config;

  const _RoleOverview({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF233E8B).withOpacity(0.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              config.icon,
              color: const Color(0xFF233E8B),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF00184A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  config.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D8CB2),
                    fontSize: 12,
                    height: 1.25,
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

class _UpcomingMeetingCard extends ConsumerWidget {
  final int currentUserId;
  final String title;
  final String dateTimeText;
  final String location;
  final String daysText;

  const _UpcomingMeetingCard({
    required this.currentUserId,
    required this.title,
    required this.dateTimeText,
    required this.location,
    required this.daysText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: const Color(0xFF233E8B),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MeetingListScreen()),
          );
          ref.refresh(dashboardSummaryProvider(currentUserId));
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFFFFB52E),
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (daysText.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB52E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          daysText,
                          style: const TextStyle(
                            color: Color(0xFF00184A),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFFD8E2FF),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$dateTimeText · $location',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFD8E2FF),
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuGrid extends ConsumerWidget {
  final List<_MenuTileData> tiles;
  final int currentUserId;

  const _MenuGrid({
    required this.tiles,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsiveColumnCount(
          constraints.maxWidth,
          compact: constraints.maxWidth < 380 ? 1 : 2,
          medium: 3,
          expanded: 4,
          large: 4,
        );
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 3.8 : 2.25,
          ),
          itemBuilder: (context, index) {
        final item = tiles[index];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.screen),
              );
              ref.refresh(dashboardSummaryProvider(currentUserId));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF233E8B).withOpacity(0.09),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      item.icon,
                      color: const Color(0xFF233E8B),
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF00184A),
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA6C5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xFFFFB52E).withOpacity(0.12),
        border: Border.all(color: const Color(0xFFFFB52E).withOpacity(0.7)),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Color(0xFFFFB52E),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MenuTileData {
  final String title;
  final IconData icon;
  final Widget screen;

  const _MenuTileData(this.title, this.icon, this.screen);
}

class _RoleDashboardConfig {
  final String title;
  final String subtitle;
  final String menuTitle;
  final IconData icon;
  final List<String> summaryKeys;
  final List<_MenuTileData> tiles;

  const _RoleDashboardConfig({
    required this.title,
    required this.subtitle,
    required this.menuTitle,
    required this.icon,
    required this.summaryKeys,
    required this.tiles,
  });

  factory _RoleDashboardConfig.forRole(String role) {
    final access = RoleAccess(role);

    if (access.isAdmin) {
      return const _RoleDashboardConfig(
        title: 'Admin Dashboard',
        subtitle: 'Manage users, meetings, approvals, and system settings.',
        menuTitle: 'Management',
        icon: Icons.admin_panel_settings_rounded,
        summaryKeys: [
          'users',
          'meetings',
          'circulars',
          'approvals',
        ],
        tiles: _adminTiles,
      );
    }

    if (access.isSecretary) {
      return const _RoleDashboardConfig(
        title: 'Secretary Dashboard',
        subtitle: 'Manage meetings, categories, papers, and agenda attachments.',
        menuTitle: 'Operations',
        icon: Icons.event_available_rounded,
        summaryKeys: [
          'meetings',
          'circulars',
          'papers',
          'comments',
        ],
        tiles: _secretaryTiles,
      );
    }

    return const _RoleDashboardConfig(
      title: 'Member Dashboard',
      subtitle: 'View meetings, papers, and board categories.',
      menuTitle: 'My Workspace',
      icon: Icons.person_rounded,
      summaryKeys: [
        'meetings',
        'papers',
        'documents',
      ],
      tiles: _memberTiles,
    );
  }
}

const _adminTiles = [
  _MenuTileData(
    'Users',
    Icons.people_outline_rounded,
    UserListScreen(),
  ),
  _MenuTileData(
    'Devices',
    Icons.devices_other_rounded,
    DeviceListScreen(),
  ),
  _MenuTileData(
    'Reports',
    Icons.bar_chart_rounded,
    ReportHomeScreen(),
  ),
  _MenuTileData(
    'Settings',
    Icons.settings_outlined,
    SettingHomeScreen(),
  ),
  _MenuTileData(
    'Access Control',
    Icons.verified_user_outlined,
    AccessValidationScreen(),
  ),
];

const _secretaryTiles = [
  _MenuTileData(
    'Privileges',
    Icons.admin_panel_settings_outlined,
    PrivilegeListScreen(),
  ),
  _MenuTileData(
    'Meetings',
    Icons.event_note_outlined,
    MeetingListScreen(),
  ),
  _MenuTileData(
    'Categories',
    Icons.category_outlined,
    CategoryListScreen(),
  ),
  _MenuTileData(
    'Subcategories',
    Icons.account_tree_outlined,
    SubcategoryListScreen(),
  ),
  _MenuTileData(
    'Papers',
    Icons.picture_as_pdf_outlined,
    PaperListScreen(),
  ),
];

const _memberTiles = [
  _MenuTileData(
    'Meetings',
    Icons.event_note_outlined,
    MeetingListScreen(),
  ),
  _MenuTileData(
    'Papers',
    Icons.picture_as_pdf_outlined,
    PaperListScreen(),
  ),
];

List<_SummaryCard> _summaryCardsForRole(
  DashboardSummaryModel summary,
  _RoleDashboardConfig config,
) {
  final cards = <String, _SummaryCard>{
    'users': _SummaryCard(
      title: 'Users',
      value: summary.totalUsers.toString(),
      icon: Icons.people_outline_rounded,
      iconColor: const Color(0xFF233E8B),
      iconBg: const Color(0xFFEAF0FF),
    ),
    'meetings': _SummaryCard(
      title: 'Meetings',
      value: summary.totalMeetings.toString(),
      icon: Icons.event_rounded,
      iconColor: DashboardScreen.gold,
      iconBg: const Color(0xFFFFF3DC),
    ),
    'circulars': _SummaryCard(
      title: 'Circulars',
      value: summary.totalCirculars.toString(),
      icon: Icons.mail_outline_rounded,
      iconColor: const Color(0xFFE84393),
      iconBg: const Color(0xFFFFE7F2),
    ),
    'approvals': _SummaryCard(
      title: 'Pending Approvals',
      value: summary.pendingApprovals.toString(),
      icon: Icons.how_to_vote_rounded,
      iconColor: const Color(0xFF3168F4),
      iconBg: const Color(0xFFEAF0FF),
    ),
    'papers': _SummaryCard(
      title: 'Unread Papers',
      value: summary.unreadPapers.toString(),
      icon: Icons.picture_as_pdf_rounded,
      iconColor: const Color(0xFFE74C3C),
      iconBg: const Color(0xFFFFEAEA),
    ),
    'comments': _SummaryCard(
      title: 'Shared Comments',
      value: summary.sharedComments.toString(),
      icon: Icons.comment_outlined,
      iconColor: const Color(0xFF20C997),
      iconBg: const Color(0xFFE0F8F1),
    ),
    'documents': _SummaryCard(
      title: 'Shared Docs',
      value: summary.sharedDocuments.toString(),
      icon: Icons.share_rounded,
      iconColor: const Color(0xFF7C3AED),
      iconBg: const Color(0xFFF1EAFE),
    ),
    'privileges': _SummaryCard(
      title: 'Privileges',
      value: summary.totalUsers.toString(),
      icon: Icons.admin_panel_settings_outlined,
      iconColor: const Color(0xFF233E8B),
      iconBg: const Color(0xFFEAF0FF),
    ),
  };

  // Some roles' `summaryKeys` may reference keys not present in `cards`.
  // Map then filter nulls to avoid the null-check operator causing a crash.
  return config.summaryKeys
      .map((key) => cards[key])
      .whereType<_SummaryCard>()
      .toList();
}

String _greetingText() {
  final hour = DateTime.now().hour;

  if (hour < 12) return 'Good Morning,';
  if (hour < 17) return 'Good Afternoon,';
  return 'Good Evening,';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}

String _weekDayName(int day) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
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
