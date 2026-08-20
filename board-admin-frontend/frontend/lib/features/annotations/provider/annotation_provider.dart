import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/annotation_repository.dart';
import '../model/annotation_backup_model.dart';
import '../model/annotation_model.dart';
import '../model/annotation_request.dart';
import '../model/annotation_restore_request.dart';

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  return AnnotationRepository(ref.read(dioProvider));
});

final annotationListProvider =
    StateNotifierProvider.family<
      AnnotationNotifier,
      AsyncValue<List<AnnotationModel>>,
      ({int paperId, int userId})
    >((ref, args) {
      return AnnotationNotifier(
        ref.read(annotationRepositoryProvider),
        args.paperId,
        args.userId,
      )..load();
    });

class AnnotationNotifier
    extends StateNotifier<AsyncValue<List<AnnotationModel>>> {
  final AnnotationRepository repository;
  final int paperId;
  final int userId;

  AnnotationNotifier(this.repository, this.paperId, this.userId)
    : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getByPaperAndUser(paperId, userId);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> create(AnnotationRequest request) async {
    await repository.create(request);
    await load();
  }

  Future<AnnotationBackupModel> backup() async {
    return repository.backup(userId);
  }

  Future<void> restore(AnnotationRestoreRequest request) async {
    await repository.restore(request);
    await load();
  }
}
