import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/report_repository.dart';
import '../model/audit_log_model.dart';
import '../model/license_utilization_model.dart';
import '../model/login_history_model.dart';
import '../model/pending_approval_report_model.dart';
import '../model/user_category_report_model.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.read(dioProvider));
});

final loginHistoryProvider = FutureProvider<List<LoginHistoryModel>>((
  ref,
) async {
  return ref.read(reportRepositoryProvider).getLoginHistory();
});

final auditLogProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  return ref.read(reportRepositoryProvider).getAuditLogs();
});

final userCategoryReportProvider =
    FutureProvider<List<UserCategoryReportModel>>((ref) async {
      return ref.read(reportRepositoryProvider).getUserCategoryReport();
    });

final licenseUtilizationProvider = FutureProvider<LicenseUtilizationModel>((
  ref,
) async {
  return ref.read(reportRepositoryProvider).getLicenseUtilization();
});

final pendingApprovalReportProvider =
    FutureProvider<List<PendingApprovalReportModel>>((ref) async {
      return ref.read(reportRepositoryProvider).getPendingApprovals();
    });
