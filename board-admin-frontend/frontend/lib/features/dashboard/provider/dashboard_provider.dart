import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/dashboard_repository.dart';
import '../model/dashboard_summary_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(dioProvider));
});

final dashboardSummaryProvider =
    FutureProvider.family<DashboardSummaryModel, int>((ref, userId) async {
      return ref.read(dashboardRepositoryProvider).getSummary(userId);
    });
