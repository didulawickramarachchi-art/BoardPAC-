import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/action_item_repository.dart';
import '../model/action_item_model.dart';

final actionItemRepositoryProvider = Provider(
  (ref) => ActionItemRepository(ref.read(dioProvider)),
);
final actionItemProvider =
    StateNotifierProvider.family<
      ActionItemNotifier,
      AsyncValue<List<ActionItemModel>>,
      int
    >(
      (ref, id) =>
          ActionItemNotifier(ref.read(actionItemRepositoryProvider), id)
            ..load(),
    );

class ActionItemNotifier
    extends StateNotifier<AsyncValue<List<ActionItemModel>>> {
  final ActionItemRepository repository;
  final int meetingId;
  ActionItemNotifier(this.repository, this.meetingId)
    : super(const AsyncLoading());
  Future<void> load() async {
    try {
      state = AsyncData(await repository.list(meetingId));
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> create({
    required String title,
    String? description,
    required int assigneeUserId,
    DateTime? dueDate,
  }) async {
    await repository.create(
      meetingId,
      title: title,
      description: description,
      assigneeUserId: assigneeUserId,
      dueDate: dueDate,
    );
    await load();
  }

  Future<void> status(int id, String value, String? note) async {
    await repository.updateStatus(meetingId, id, value, note);
    await load();
  }

  Future<void> delete(int id) async {
    await repository.delete(meetingId, id);
    await load();
  }
}
