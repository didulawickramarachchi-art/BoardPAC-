import 'package:flutter/material.dart';
import 'audit_log_screen.dart';
import 'license_utilization_screen.dart';
import 'login_history_screen.dart';
import 'pending_approval_screen.dart';
import 'user_category_report_screen.dart';

class ReportHomeScreen extends StatelessWidget {
  const ReportHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Login History', const LoginHistoryScreen()),
      ('Audit Logs', const AuditLogScreen()),
      ('User Category Report', const UserCategoryReportScreen()),
      ('License Utilization', const LicenseUtilizationScreen()),
      ('Pending Approvals', const PendingApprovalScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              title: Text(item.$1),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.$2),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
