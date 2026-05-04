import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/approval_repository.dart';
import '../model/approval_model.dart';
import '../model/approval_request.dart';

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  return ApprovalRepository(ref.read(dioProvider));
});

final approvalListProvider = StateNotifierProvider.family<
    ApprovalNotifier, AsyncValue<List<ApprovalModel>>, int>((ref, paperId) {
  return ApprovalNotifier(ref.read(approvalRepositoryProvider), paperId)..load();
});

class ApprovalNotifier extends StateNotifier<AsyncValue<List<ApprovalModel>>> {
  final ApprovalRepository repository;
  final int paperId;

  ApprovalNotifier(this.repository, this.paperId) : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getByPaper(paperId);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> submit(ApprovalRequest request) async {
    await repository.submitApproval(request);
    await load();
  }
}