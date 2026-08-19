import 'package:dio/dio.dart';
import '../model/audit_log_model.dart';
import '../model/license_utilization_model.dart';
import '../model/login_history_model.dart';
import '../model/meeting_history_report_model.dart';
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

  Map<String, dynamic> _meetingHistoryParams({
    int? categoryId,
    int? subcategoryId,
    DateTime? from,
    DateTime? to,
  }) {
    final parameters = <String, dynamic>{};
    parameters['categoryId'] = categoryId;
    parameters['subcategoryId'] = subcategoryId;
    if (from != null) parameters['from'] = _date(from);
    if (to != null) parameters['to'] = _date(to);
    parameters.removeWhere((_, value) => value == null);
    return parameters;
  }

  Future<List<MeetingHistoryReportModel>> getMeetingHistory({
    int? categoryId,
    int? subcategoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await dio.get(
      '/meeting-history-report',
      queryParameters: _meetingHistoryParams(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        from: from,
        to: to,
      ),
    );
    return (response.data as List)
        .map((item) => MeetingHistoryReportModel.fromJson(item))
        .toList();
  }

  Future<List<int>> downloadMeetingHistoryPdf({
    int? categoryId,
    int? subcategoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await dio.get<List<int>>(
      '/meeting-history-report/pdf',
      queryParameters: _meetingHistoryParams(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        from: from,
        to: to,
      ),
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
