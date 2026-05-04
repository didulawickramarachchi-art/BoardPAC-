import 'package:dio/dio.dart';
import '../model/dashboard_summary_model.dart';

class DashboardRepository {
  final Dio dio;

  DashboardRepository(this.dio);

  Future<DashboardSummaryModel> getSummary(int userId) async {
    final response = await dio.get('/dashboard/summary/$userId');
    return DashboardSummaryModel.fromJson(response.data);
  }
}