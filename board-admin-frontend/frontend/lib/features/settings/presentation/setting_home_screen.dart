import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../auth/provider/auth_provider.dart';
import 'setting_group_screen.dart';

class SettingHomeScreen extends ConsumerWidget {
  const SettingHomeScreen({super.key});

  static const Color navy = Color(0xFF14275B);
  static const Color bgColor = Color(0xFFF6F7FC);
  static const Color cardColor = Colors.white;
  static const Color iconBg = Color(0xFFE9ECF3);
  static const Color arrowBg = Color(0xFFFFF1D8);
  static const Color subTextColor = Color(0xFF6E7FA8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');

    if (!access.canManageSettings) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text('You do not have access to settings.'),
        ),
      );
    }

    final groups = const [
      SettingGroupItem(
        title: 'Meeting & Circular',
        group: 'MEETING_CIRCULAR',
        subtitle: 'Manage meeting and circular settings',
        icon: Icons.event_note_rounded,
      ),
      SettingGroupItem(
        title: 'Agenda',
        group: 'AGENDA',
        subtitle: 'Configure agenda related settings',
        icon: Icons.list_alt_rounded,
      ),
      SettingGroupItem(
        title: 'Paper',
        group: 'PAPER',
        subtitle: 'Manage paper settings and rules',
        icon: Icons.description_rounded,
      ),
      SettingGroupItem(
        title: 'User Management',
        group: 'USER_MANAGEMENT',
        subtitle: 'Control user management settings',
        icon: Icons.manage_accounts_rounded,
      ),
      SettingGroupItem(
        title: 'Comment',
        group: 'COMMENT',
        subtitle: 'Manage comment permissions',
        icon: Icons.comment_rounded,
      ),
      SettingGroupItem(
        title: 'General',
        group: 'GENERAL',
        subtitle: 'Update general system settings',
        icon: Icons.settings_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = groups[index];

            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingGroupScreen(group: item.group),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: navy, size: 25),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: navy,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: subTextColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: arrowBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: navy,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SettingGroupItem {
  final String title;
  final String group;
  final String subtitle;
  final IconData icon;

  const SettingGroupItem({
    required this.title,
    required this.group,
    required this.subtitle,
    required this.icon,
  });
}
