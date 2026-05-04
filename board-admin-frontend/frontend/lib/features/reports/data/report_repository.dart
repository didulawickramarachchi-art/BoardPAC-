import 'package:dio/dio.dart';
import '../model/audit_log_model.dart';
import '../model/license_utilization_model.dart';
import '../model/login_history_model.dart';
import '../model/pending_approval_report_model.dart';
import '../model/user_category_report_model.dart';

class ReportRepository {
  final Dio dio;

  ReportRepository(this.dio);

  Future<List<LoginHistoryModel>> getLoginHistory() async {
    final response = await dio.get('/reports/login-history');
    return (response.data as List)
        .map((e) => LoginHistoryModel.fromJson(e))
        .toList();
  }

  Future<List<AuditLogModel>> getAuditLogs() async {
    final response = await dio.get('/reports/audit-logs');
    return (response.data as List)
        .map((e) => AuditLogModel.fromJson(e))
        .toList();
  }

  Future<List<UserCategoryReportModel>> getUserCategoryReport() async {
    final response = await dio.get('/admin-reports/user-category');
    return (response.data as List)
        .map((e) => UserCategoryReportModel.fromJson(e))
        .toList();
  }

  Future<LicenseUtilizationModel> getLicenseUtilization() async {
    final response = await dio.get('/admin-reports/license-utilization');
    return LicenseUtilizationModel.fromJson(response.data);
  }

  Future<List<PendingApprovalReportModel>> getPendingApprovals() async {
    final response = await dio.get('/admin-reports/pending-approvals');
    return (response.data as List)
        .map((e) => PendingApprovalReportModel.fromJson(e))
        .toList();
  }
}
