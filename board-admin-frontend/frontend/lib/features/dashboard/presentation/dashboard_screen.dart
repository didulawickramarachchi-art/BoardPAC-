import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/access_control/presentation/access_validation_screen.dart';
import 'package:frontend/features/reports/presentation/report_home_screen.dart';
import 'package:frontend/features/reports/presentation/meeting_history_report_screen.dart';
import 'package:frontend/features/settings/presentation/setting_home_screen.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../auth/provider/auth_provider.dart';
import '../../categories/presentation/category_list_screen.dart';
import '../../devices/model/device_model.dart';
import '../../devices/presentation/device_list_screen.dart';
import '../../devices/provider/device_provider.dart';
import '../../meetings/presentation/meeting_list_screen.dart';
import '../../notifications/model/notification_model.dart';
import '../../notifications/model/notification_request.dart';
import '../../notifications/provider/notification_provider.dart';
import '../../papers/presentation/paper_list_screen.dart';
import '../../privileges/presentation/privilege_list_screen.dart';
import '../../subcategories/presentation/subcategory_list_screen.dart';
import '../../users/presentation/user_list_screen.dart';
import '../../users/presentation/profile_picture_screen.dart';
import '../../users/provider/user_provider.dart';
import '../../users/model/user_model.dart';
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
    final isAdmin = RoleAccess(role).isAdmin;
    final usersAsync = isAdmin ? ref.watch(userListProvider) : null;
    final devicesAsync = isAdmin ? ref.watch(deviceListProvider) : null;

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
                        data: (summary) {
                          if (!isAdmin) {
                            return _SummaryGrid(
                              cards: _summaryCardsForRole(summary, config),
                            );
                          }

                          return usersAsync!.when(
                            data: (users) => devicesAsync!.when(
                              data: (devices) => _SummaryGrid(
                                cards: _summaryCardsForRole(
                                  summary,
                                  config,
                                  users: users,
                                  devices: devices,
                                ),
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, _) =>
                                  _ErrorBox(message: error.toString()),
                            ),
                            loading: () => const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, _) =>
                                _ErrorBox(message: error.toString()),
                          );
                        },

                        loading: () => const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        ),

                        error: (error, _) =>
                            _ErrorBox(message: error.toString()),
                      ),

                      if (!isAdmin) ...[
                        summaryAsync.when(
                          data: (summary) {
                            final meetingDate = DateTime.tryParse(
                              summary.upcomingMeetingDateTime ?? '',
                            )?.toLocal();
                            if (summary.upcomingMeetingTitle == null ||
                                meetingDate == null ||
                                !meetingDate.isAfter(DateTime.now())) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                const _SectionTitle(title: 'Upcoming Meeting'),
                                const SizedBox(height: 10),
                                _UpcomingMeetingCard(
                                  currentUserId: currentUserId,
                                  title: summary.upcomingMeetingTitle!,
                                  dateTimeText:
                                      summary.upcomingMeetingDateTime!,
                                  location:
                                      summary.upcomingMeetingLocation ??
                                      'No location',
                                  daysText:
                                      summary.upcomingMeetingDaysText ?? '',
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],

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
    final currentUserId = authState.userId;
    final unreadNotifications = currentUserId == null
        ? 0
        : ref
                  .watch(notificationListProvider(currentUserId))
                  .valueOrNull
                  ?.where((notification) => !notification.read)
                  .length ??
              0;

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

              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      if (currentUserId != null) {
                        ref
                            .read(
                              notificationListProvider(currentUserId).notifier,
                            )
                            .markAllRead();
                      }
                      _showNotificationsSheet(
                        context,
                        currentUserId: currentUserId,
                        role: role,
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      right: -2,
                      top: -4,
                      child: _NotificationBadge(count: unreadNotifications),
                    ),
                ],
              ),

              const SizedBox(width: 8),

              IconButton(
                tooltip: 'Logout',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
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
                          child:
                              profilePicture?.when(
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
                                    return _ProfileInitials(initials: initials);
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
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
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

void _showNotificationsSheet(
  BuildContext context, {
  required int? currentUserId,
  required String role,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) =>
        _NotificationsSheet(currentUserId: currentUserId, role: role),
  );
}

class _NotificationsSheet extends ConsumerWidget {
  final int? currentUserId;
  final String role;

  const _NotificationsSheet({required this.currentUserId, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = currentUserId;
    final notificationsAsync = userId == null
        ? const AsyncValue<List<NotificationModel>>.data([])
        : ref.watch(notificationListProvider(userId));
    final canAnnounce = RoleAccess(role).isSecretary;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE1E6F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DashboardScreen.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: DashboardScreen.darkBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: DashboardScreen.darkBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (userId != null)
                        TextButton(
                          onPressed:
                              notificationsAsync.valueOrNull?.isEmpty == false
                              ? () => ref
                                    .read(
                                      notificationListProvider(userId).notifier,
                                    )
                                    .clear()
                              : null,
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (canAnnounce) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardScreen.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: userId == null
                      ? null
                      : () => _showAnnouncementDialog(context, ref, userId),
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Create Announcement'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Flexible(
              child: notificationsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const _NotificationsEmptyState();
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _NotificationTile(
                        notification: items[index],
                        currentUserId: userId,
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _NotificationsError(
                  message: error.toString(),
                  onRetry: userId == null
                      ? null
                      : () => ref
                            .read(notificationListProvider(userId).notifier)
                            .load(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAnnouncementDialog(
    BuildContext context,
    WidgetRef ref,
    int userId,
  ) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    var isSending = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 4,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      final message = messageController.text.trim();

                      if (title.isEmpty || message.isEmpty) {
                        setState(() {
                          errorMessage = 'Please enter a title and message.';
                        });
                        return;
                      }

                      setState(() {
                        isSending = true;
                        errorMessage = null;
                      });

                      try {
                        await ref
                            .read(notificationListProvider(userId).notifier)
                            .createAnnouncement(
                              NotificationRequest(
                                title: title,
                                message: message,
                                type: 'ANNOUNCEMENT',
                                createdByUserId: userId,
                                announcement: true,
                              ),
                            );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (error) {
                        setState(() {
                          isSending = false;
                          errorMessage = error.toString();
                        });
                      }
                    },
              child: Text(isSending ? 'Sending...' : 'Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final int count;

  const _NotificationBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: DashboardScreen.primaryBlue, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  final int? currentUserId;

  const _NotificationTile({
    required this.notification,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _notificationColor(notification.type);
    final senderAvatar = _NotificationSenderAvatar(
      notification: notification,
      color: color,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.read ? DashboardScreen.bgColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: notification.read
              ? const Color(0xFFE3E8F2)
              : DashboardScreen.gold.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          senderAvatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.createdByName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6E7FA8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: DashboardScreen.darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (notification.message.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF6E7FA8),
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _NotificationReactions(
                  notification: notification,
                  userId: currentUserId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _notificationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'MEETING_CREATED':
        return Icons.event_available_outlined;
      case 'PAPER_CREATED':
      case 'PAPER_SHARED':
        return Icons.picture_as_pdf_outlined;
      case 'DOCUMENT_UPLOADED':
        return Icons.upload_file_outlined;
      case 'COMMENT_SHARED':
        return Icons.comment_outlined;
      case 'ANNOUNCEMENT':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  static Color _notificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'ANNOUNCEMENT':
        return DashboardScreen.gold;
      case 'COMMENT_SHARED':
        return const Color(0xFF20C997);
      case 'DOCUMENT_UPLOADED':
        return const Color(0xFF7C3AED);
      case 'PAPER_CREATED':
      case 'PAPER_SHARED':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF233E8B);
    }
  }
}

class _NotificationReactions extends ConsumerWidget {
  final NotificationModel notification;
  final int? userId;

  const _NotificationReactions({
    required this.notification,
    required this.userId,
  });

  static const reactions = [
    ('LIKE', Icons.thumb_up_alt_outlined),
    ('LOVE', Icons.favorite_border_rounded),
    ('OK', Icons.check_circle_outline_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: reactions.map((reaction) {
        final type = reaction.$1;
        final count = notification.reactionCounts[type] ?? 0;
        final selected = notification.currentReaction == type;

        return InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: userId == null
              ? null
              : () => ref
                    .read(notificationListProvider(userId!).notifier)
                    .react(notification.id, type),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? DashboardScreen.primaryBlue
                  : const Color(0xFFF1F4FA),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: selected
                    ? DashboardScreen.primaryBlue
                    : const Color(0xFFE1E6F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  reaction.$2,
                  size: 15,
                  color: selected ? Colors.white : const Color(0xFF6E7FA8),
                ),
                const SizedBox(width: 5),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF6E7FA8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NotificationSenderAvatar extends ConsumerWidget {
  final NotificationModel notification;
  final Color color;

  const _NotificationSenderAvatar({
    required this.notification,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = notification.createdByUserId;
    final pictureUrl = notification.createdByProfilePictureUrl;
    final hasPicture = userId != null && pictureUrl != null;
    final picture = hasPicture
        ? ref.watch(profilePictureProvider((userId: userId, url: pictureUrl)))
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child:
              picture?.when(
                data: (bytes) => Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _SenderInitials(
                    name: notification.createdByName,
                    color: color,
                  ),
                ),
                loading: () => const Center(
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => _SenderInitials(
                  name: notification.createdByName,
                  color: color,
                ),
              ) ??
              _SenderInitials(name: notification.createdByName, color: color),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              _NotificationTile._notificationIcon(notification.type),
              color: color,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SenderInitials extends StatelessWidget {
  final String name;
  final Color color;

  const _SenderInitials({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: DashboardScreen.bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF7D8CB2),
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'No notifications yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DashboardScreen.darkBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _NotificationsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load notifications: $message',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
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
            color: Colors.black.withValues(alpha: 0.035),
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
            color: Colors.black.withValues(alpha: 0.035),
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
              color: const Color(0xFF233E8B).withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(config.icon, color: const Color(0xFF233E8B), size: 23),
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
          ref.invalidate(dashboardSummaryProvider(currentUserId));
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
                  color: Colors.white.withValues(alpha: 0.12),
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

  const _MenuGrid({required this.tiles, required this.currentUserId});

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
                  ref.invalidate(dashboardSummaryProvider(currentUserId));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
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
                          color: const Color(
                            0xFF233E8B,
                          ).withValues(alpha: 0.09),
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
        color: const Color(0xFFFFB52E).withValues(alpha: 0.12),
        border: Border.all(
          color: const Color(0xFFFFB52E).withValues(alpha: 0.7),
        ),
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
        summaryKeys: ['members', 'secretaries', 'admins', 'pendingDevices'],
        tiles: _adminTiles,
      );
    }

    if (access.isSecretary) {
      return const _RoleDashboardConfig(
        title: 'Secretary Dashboard',
        subtitle:
            'Manage meetings, categories, papers, and agenda attachments.',
        menuTitle: 'Operations',
        icon: Icons.event_available_rounded,
        summaryKeys: ['meetings', 'circulars', 'papers', 'comments'],
        tiles: _secretaryTiles,
      );
    }

    return const _RoleDashboardConfig(
      title: 'Member Dashboard',
      subtitle: 'View meetings, papers, and board categories.',
      menuTitle: 'My Workspace',
      icon: Icons.person_rounded,
      summaryKeys: ['meetings', 'approvals', 'papers', 'comments', 'documents'],
      tiles: _memberTiles,
    );
  }
}

const _adminTiles = [
  _MenuTileData('Users', Icons.people_outline_rounded, UserListScreen()),
  _MenuTileData('Devices', Icons.devices_other_rounded, DeviceListScreen()),
  _MenuTileData('Reports', Icons.bar_chart_rounded, ReportHomeScreen()),
  _MenuTileData('Settings', Icons.settings_outlined, SettingHomeScreen()),
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
  _MenuTileData('Meetings', Icons.event_note_outlined, MeetingListScreen()),
  _MenuTileData('Categories', Icons.category_outlined, CategoryListScreen()),
  _MenuTileData(
    'Subcategories',
    Icons.account_tree_outlined,
    SubcategoryListScreen(),
  ),
  _MenuTileData('Papers', Icons.picture_as_pdf_outlined, PaperListScreen()),
  _MenuTileData(
    'Meeting History Report',
    Icons.summarize_outlined,
    MeetingHistoryReportScreen(),
  ),
];

const _memberTiles = [
  _MenuTileData('Meetings', Icons.event_note_outlined, MeetingListScreen()),
  _MenuTileData('Papers', Icons.picture_as_pdf_outlined, PaperListScreen()),
];

List<_SummaryCard> _summaryCardsForRole(
  DashboardSummaryModel summary,
  _RoleDashboardConfig config, {
  List<UserModel>? users,
  List<DeviceModel>? devices,
}) {
  final roleCounts = _UserRoleCounts.fromUsers(users ?? const []);
  final cards = <String, _SummaryCard>{
    'members': _SummaryCard(
      title: 'Members',
      value: roleCounts.members.toString(),
      icon: Icons.groups_2_outlined,
      iconColor: const Color(0xFF233E8B),
      iconBg: const Color(0xFFEAF0FF),
    ),
    'secretaries': _SummaryCard(
      title: 'Secretaries',
      value: roleCounts.secretaries.toString(),
      icon: Icons.badge_outlined,
      iconColor: DashboardScreen.gold,
      iconBg: const Color(0xFFFFF3DC),
    ),
    'admins': _SummaryCard(
      title: 'Admins',
      value: roleCounts.admins.toString(),
      icon: Icons.admin_panel_settings_outlined,
      iconColor: const Color(0xFFE84393),
      iconBg: const Color(0xFFFFE7F2),
    ),
    'pendingDevices': _SummaryCard(
      title: 'Pending User Device Approvals',
      value: (devices ?? const <DeviceModel>[])
          .where((device) => device.isPending)
          .length
          .toString(),
      icon: Icons.person_add_alt_1_rounded,
      iconColor: const Color(0xFF3168F4),
      iconBg: const Color(0xFFEAF0FF),
    ),
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

class _UserRoleCounts {
  final int members;
  final int secretaries;
  final int admins;

  const _UserRoleCounts({
    required this.members,
    required this.secretaries,
    required this.admins,
  });

  factory _UserRoleCounts.fromUsers(List<UserModel> users) {
    var members = 0;
    var secretaries = 0;
    var admins = 0;

    for (final user in users) {
      final role = user.role?.trim().toUpperCase().replaceAll('-', '_') ?? '';

      if (const {
        'ADMIN',
        'SUPER_ADMIN',
        'BOARD_ADMIN',
        'SUPPORT_TEAM',
      }.contains(role)) {
        admins++;
      } else if (const {
        'SECRETARY',
        'BOARD_SECRETARY',
        'ORGANIZER',
      }.contains(role)) {
        secretaries++;
      } else if (role == 'MEMBER') {
        members++;
      }
    }

    return _UserRoleCounts(
      members: members,
      secretaries: secretaries,
      admins: admins,
    );
  }
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
