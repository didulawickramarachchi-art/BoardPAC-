import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/category_image_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../../notifications/provider/notification_provider.dart';
import '../../categories/provider/category_provider.dart';
import '../../agendas/presentation/agenda_section_screen.dart';
import '../../papers/presentation/paper_list_screen.dart';
import '../../subcategories/provider/subcategory_provider.dart';
import '../provider/meeting_provider.dart';
import 'meeting_detail_screen.dart';
import 'meeting_form_screen.dart';

class MeetingListScreen extends ConsumerStatefulWidget {
  final bool initiallyShowHistory;
  final String? meetingType;

  const MeetingListScreen({
    super.key,
    this.initiallyShowHistory = false,
    this.meetingType,
  });

  @override
  ConsumerState<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends ConsumerState<MeetingListScreen> {
  static const _categoryPreferencePrefix = 'member_meeting_category_';
  static const _subcategoryPreferencePrefix = 'member_meeting_subcategory_';
  String? selectedCategory;
  String? selectedSubcategory;
  late bool showHistory;

  @override
  void initState() {
    super.initState();
    showHistory = widget.initiallyShowHistory;
    _restoreMemberFilters();
  }

  Future<void> _restoreMemberFilters() async {
    final auth = ref.read(authProvider);
    if (!RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile).isMember) return;
    final userId = auth.userId;
    if (userId == null) return;
    final storage = SecureStorageService();
    final category = await storage.read('$_categoryPreferencePrefix$userId');
    final subcategory = await storage.read(
      '$_subcategoryPreferencePrefix$userId',
    );
    if (!mounted) return;
    setState(() {
      selectedCategory = _storedValue(category);
      selectedSubcategory = _storedValue(subcategory);
    });
  }

  Future<void> _saveMemberFilters(RoleAccess access, int? userId) async {
    if (!access.isMember || userId == null) return;
    final storage = SecureStorageService();
    await storage.write(
      '$_categoryPreferencePrefix$userId',
      selectedCategory ?? '',
    );
    await storage.write(
      '$_subcategoryPreferencePrefix$userId',
      selectedSubcategory ?? '',
    );
  }

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    final meetingsAsync = ref.watch(meetingListProvider);
    final categoryModels = ref.watch(categoryListProvider).valueOrNull ?? [];
    final subcategoryModels =
        ref.watch(subcategoryListProvider).valueOrNull ?? [];
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile);
    final notifications = access.isMember && auth.userId != null
        ? ref.watch(notificationListProvider(auth.userId!)).valueOrNull ?? []
        : const [];
    final unreadMeetingIds = notifications
        .where((notification) => !notification.read)
        .map((notification) => notification.relatedMeetingId)
        .whereType<int>()
        .toSet();

    if (!access.canViewMeetings) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text('You do not have access to meetings.')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: selectedCategory == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (selectedSubcategory != null) {
                      selectedSubcategory = null;
                    } else {
                      selectedCategory = null;
                    }
                  });
                  _saveMemberFilters(access, auth.userId);
                },
              ),
        title: Text(
          selectedSubcategory ??
              selectedCategory ??
              (showHistory
                  ? 'Meeting Archive'
                  : widget.meetingType == 'CIRCULAR'
                  ? 'Circulars'
                  : 'Meetings'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _MeetingTab(
                    icon: Icons.event_available_outlined,
                    label: 'Current',
                    selected: !showHistory,
                    onTap: () => setState(() {
                      showHistory = false;
                      selectedCategory = null;
                      selectedSubcategory = null;
                    }),
                  ),
                  _MeetingTab(
                    icon: Icons.history_rounded,
                    label: 'History',
                    selected: showHistory,
                    onTap: () => setState(() {
                      showHistory = true;
                      selectedCategory = null;
                      selectedSubcategory = null;
                    }),
                  ),
                ],
              ),
            ),
          ),
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
          final visibleByPeriod =
              items
                  .where(
                    (meeting) =>
                        widget.meetingType == null ||
                        meeting.type.toString().toUpperCase() ==
                            widget.meetingType,
                  )
                  .where((meeting) => _isHistorical(meeting) == showHistory)
                  .toList()
                ..sort(
                  (a, b) => showHistory
                      ? b.meetingDateTime.compareTo(a.meetingDateTime)
                      : a.meetingDateTime.compareTo(b.meetingDateTime),
                );

          if (visibleByPeriod.isEmpty) {
            return AppEmptyState(
              message: showHistory
                  ? 'No expired meetings found'
                  : 'No current meetings found',
            );
          }

          if (selectedCategory == null) {
            final categories = <String, int>{};
            for (final meeting in visibleByPeriod) {
              final rawName = (meeting.categoryName ?? '').trim();
              final name = rawName.isEmpty ? 'Uncategorized' : rawName;
              categories[name] = (categories[name] ?? 0) + 1;
            }
            final unreadByCategory = <String, int>{};
            for (final meeting in visibleByPeriod) {
              if (!unreadMeetingIds.contains(meeting.id)) continue;
              final rawName = (meeting.categoryName ?? '').trim();
              final name = rawName.isEmpty ? 'Uncategorized' : rawName;
              unreadByCategory[name] = (unreadByCategory[name] ?? 0) + 1;
            }
            final names = categories.keys.toList()..sort();
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: names.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final name = names[index];
                final matching = categoryModels.where(
                  (category) =>
                      category.name == name || category.displayName == name,
                );
                return CategoryImageCard(
                  title: name,
                  subtitle: _filterSubtitle(
                    categories[name] ?? 0,
                    unreadByCategory[name] ?? 0,
                  ),
                  imageUrl: matching.isEmpty ? null : matching.first.imageUrl,
                  onTap: () {
                    setState(() {
                      selectedCategory = name;
                      selectedSubcategory = null;
                    });
                    _saveMemberFilters(access, auth.userId);
                  },
                );
              },
            );
          }

          final categoryMeetings = visibleByPeriod.where((meeting) {
            final rawName = (meeting.categoryName ?? '').trim();
            return (rawName.isEmpty ? 'Uncategorized' : rawName) ==
                selectedCategory;
          }).toList();

          if (selectedSubcategory == null) {
            final subcategories = <String, int>{};
            for (final meeting in categoryMeetings) {
              final rawName = (meeting.subcategoryName ?? '').trim();
              final name = rawName.isEmpty ? 'Unassigned' : rawName;
              subcategories[name] = (subcategories[name] ?? 0) + 1;
            }
            final unreadBySubcategory = <String, int>{};
            for (final meeting in categoryMeetings) {
              if (!unreadMeetingIds.contains(meeting.id)) continue;
              final rawName = (meeting.subcategoryName ?? '').trim();
              final name = rawName.isEmpty ? 'Unassigned' : rawName;
              unreadBySubcategory[name] = (unreadBySubcategory[name] ?? 0) + 1;
            }
            final names = subcategories.keys.toList()..sort();
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: names.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final name = names[index];
                final matches = subcategoryModels.where(
                  (subcategory) =>
                      subcategory.name == name &&
                      (subcategory.categoryName == selectedCategory ||
                          categoryMeetings.any(
                            (meeting) =>
                                meeting.subcategoryId == subcategory.id,
                          )),
                );
                final displayName = matches.isEmpty
                    ? name
                    : matches.first.displayName;
                return _SubcategoryMeetingCard(
                  title: displayName,
                  subtitle: _filterSubtitle(
                    subcategories[name] ?? 0,
                    unreadBySubcategory[name] ?? 0,
                  ),
                  onTap: () {
                    setState(() => selectedSubcategory = name);
                    _saveMemberFilters(access, auth.userId);
                  },
                );
              },
            );
          }

          final visibleItems = categoryMeetings.where((meeting) {
            final rawName = (meeting.subcategoryName ?? '').trim();
            return (rawName.isEmpty ? 'Unassigned' : rawName) ==
                selectedSubcategory;
          }).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visibleItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final meeting = visibleItems[index];

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    if (showHistory) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MeetingDetailScreen(
                            meeting: meeting,
                            isHistorical: true,
                          ),
                        ),
                      );
                    } else {
                      _showMeetingOptions(context, meeting, access);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
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
                            color: primaryBlue.withValues(alpha: 0.08),
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
                                    bgColor: gold.withValues(alpha: 0.16),
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

                              if ((meeting.subcategoryName ?? '')
                                  .isNotEmpty) ...[
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
                                color: primaryBlue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.more_vert_rounded,
                                color: primaryBlue,
                                size: 22,
                              ),
                            ),
                            onSelected: (value) async {
                              if (value == 'delete') {
                                _showDeleteDialog(context, ref, meeting);
                                return;
                              }

                              await _changeMeetingStatus(
                                context,
                                ref,
                                meeting,
                                open: value == 'open',
                              );
                            },
                            itemBuilder: (_) {
                              final status = meeting.status
                                  .toString()
                                  .trim()
                                  .toUpperCase();
                              return [
                                if (status == 'DRAFT')
                                  const PopupMenuItem(
                                    value: 'open',
                                    child: _PopupItem(
                                      icon: Icons.lock_open_outlined,
                                      text: 'Open',
                                    ),
                                  ),
                                if (status == 'OPEN')
                                  const PopupMenuItem(
                                    value: 'close',
                                    child: _PopupItem(
                                      icon: Icons.lock_outline,
                                      text: 'Close',
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: _PopupItem(
                                    icon: Icons.delete_outline,
                                    text: 'Delete',
                                  ),
                                ),
                              ];
                            },
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

  static bool _isHistorical(dynamic meeting) {
    final status = meeting.status.toString().trim().toLowerCase();
    if (status.contains('expired') ||
        status.contains('closed') ||
        status.contains('completed') ||
        status.contains('cancelled') ||
        status.contains('canceled')) {
      return true;
    }
    final date = DateTime.tryParse(meeting.meetingDateTime)?.toLocal();
    return date != null && date.isBefore(DateTime.now());
  }

  static Future<void> _changeMeetingStatus(
    BuildContext context,
    WidgetRef ref,
    dynamic meeting, {
    required bool open,
  }) async {
    try {
      final notifier = ref.read(meetingListProvider.notifier);
      if (open) {
        await notifier.openMeeting(meeting.id);
      } else {
        await notifier.closeMeeting(meeting.id);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            open
                ? 'Meeting opened successfully'
                : 'Meeting closed and moved to history',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiErrorMessage.from(
              error,
              fallback: open
                  ? 'Failed to open meeting'
                  : 'Failed to close meeting',
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  static void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic meeting,
  ) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete meeting?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will permanently delete ${meeting.title} and all related items.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('This will remove:'),
            const SizedBox(height: 6),
            const Text('• All agenda sections and items'),
            const Text('• All papers and attachments'),
            const Text('• All approval records'),
            const Text('• All participants'),
            const Text('• All notes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;

      try {
        await ref.read(meetingListProvider.notifier).deleteMeeting(meeting.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting deleted successfully')),
        );
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete meeting: $error')),
        );
      }
    });
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
                icon: Icons.info_outline_rounded,
                title: 'Meeting Details',
                subtitle: 'View all information about this meeting',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeetingDetailScreen(meeting: meeting),
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

class _MeetingTab extends StatelessWidget {
  static const _darkBlue = Color(0xFF00184A);
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MeetingTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? _darkBlue : Colors.white),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _darkBlue : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryMeetingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SubcategoryMeetingCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF12275B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: Color(0xFF12275B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF00184A),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF7D8CB2)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA6C5)),
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

    return _SmallChip(text: status, bgColor: bgColor, textColor: textColor);
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

  const _PopupItem({required this.icon, required this.text});

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
          color: primaryBlue.withValues(alpha: 0.08),
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

String? _storedValue(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _filterSubtitle(int meetingCount, int unreadCount) {
  final meetings = '$meetingCount meeting${meetingCount == 1 ? '' : 's'}';
  if (unreadCount == 0) return meetings;
  return '$meetings - $unreadCount new update${unreadCount == 1 ? '' : 's'}';
}
