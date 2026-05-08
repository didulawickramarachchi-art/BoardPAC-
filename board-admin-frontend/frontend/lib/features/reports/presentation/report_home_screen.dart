import 'package:flutter/material.dart';
import 'audit_log_screen.dart';
import 'license_utilization_screen.dart';
import 'login_history_screen.dart';
import 'pending_approval_screen.dart';
import 'user_category_report_screen.dart';

class ReportHomeScreen extends StatelessWidget {
  const ReportHomeScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    final items = [
      _ReportItem(
        title: 'Login History',
        subtitle: 'View user login activity',
        icon: Icons.login_rounded,
        screen: const LoginHistoryScreen(),
      ),
      _ReportItem(
        title: 'Audit Logs',
        subtitle: 'Track system actions',
        icon: Icons.history_edu_rounded,
        screen: const AuditLogScreen(),
      ),
      _ReportItem(
        title: 'User Category Report',
        subtitle: 'View assigned categories and roles',
        icon: Icons.manage_accounts_outlined,
        screen: const UserCategoryReportScreen(),
      ),
      _ReportItem(
        title: 'License Utilization',
        subtitle: 'Monitor user license usage',
        icon: Icons.analytics_outlined,
        screen: const LicenseUtilizationScreen(),
      ),
      _ReportItem(
        title: 'Pending Approvals',
        subtitle: 'Review pending paper approvals',
        icon: Icons.pending_actions_rounded,
        screen: const PendingApprovalScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = items[index];

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.screen),
                );
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
                        item.icon,
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
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: darkBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7D8CB2),
                              fontSize: 12,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: darkBlue,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

  const _ReportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
  });
}