import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/access_control/presentation/access_validation_screen.dart';
import 'package:frontend/features/reports/presentation/report_home_screen.dart';
import 'package:frontend/features/settings/presentation/setting_home_screen.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
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

    final tiles = [
  _DashboardTileData('Users', Icons.people_outline, const UserListScreen()),
  _DashboardTileData('Devices', Icons.devices_other_outlined, const DeviceListScreen()),
  _DashboardTileData('Categories', Icons.category_outlined, const CategoryListScreen()),
  _DashboardTileData('Subcategories', Icons.account_tree_outlined, const SubcategoryListScreen()),
  _DashboardTileData('Privileges', Icons.admin_panel_settings_outlined, const PrivilegeListScreen()),
  _DashboardTileData('Meetings', Icons.event_note_outlined, const MeetingListScreen()),
  _DashboardTileData('Reports', Icons.bar_chart_outlined, const ReportHomeScreen()),
  _DashboardTileData('Settings', Icons.settings_outlined, const SettingHomeScreen()),
  _DashboardTileData('Access Control', Icons.verified_user_outlined, const AccessValidationScreen()),
];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            summaryAsync.when(
              data: (summary) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,

                // ✅ FIXED: smaller ratio = taller cards
                childAspectRatio: 1.15,

                children: [
                  _SummaryCard(title: 'Meetings', value: summary.totalMeetings.toString(), icon: Icons.event),
                  _SummaryCard(title: 'Circulars', value: summary.totalCirculars.toString(), icon: Icons.mail_outline),
                  _SummaryCard(title: 'Pending Approvals', value: summary.pendingApprovals.toString(), icon: Icons.how_to_vote),
                  _SummaryCard(title: 'Unread Papers', value: summary.unreadPapers.toString(), icon: Icons.picture_as_pdf),
                  _SummaryCard(title: 'Shared Comments', value: summary.sharedComments.toString(), icon: Icons.comment_outlined),
                  _SummaryCard(title: 'Shared Docs', value: summary.sharedDocuments.toString(), icon: Icons.share_outlined),
                ],
              ),
              loading: () => const SizedBox(
                height: 180,
                child: AppLoading(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final item = tiles[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.screen),
                    );
                  },
                  child: AppCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 34),
                        const SizedBox(height: 12),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _DashboardTileData {
  final String title;
  final IconData icon;
  final Widget screen;

  _DashboardTileData(this.title, this.icon, this.screen);
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}