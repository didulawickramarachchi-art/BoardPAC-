import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/agenda_repository.dart';
import '../model/agenda_item_model.dart';
import '../model/agenda_item_request.dart';
import '../model/agenda_section_model.dart';
import '../model/agenda_section_request.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository(ref.read(dioProvider));
});

final agendaSectionProvider =
    StateNotifierProvider.family<
      AgendaSectionNotifier,
      AsyncValue<List<AgendaSectionModel>>,
      int
    >((ref, meetingId) {
      return AgendaSectionNotifier(
        ref.read(agendaRepositoryProvider),
        meetingId,
      )..load();
    });

class AgendaSectionNotifier
    extends StateNotifier<AsyncValue<List<AgendaSectionModel>>> {
  final AgendaRepository repository;
  final int meetingId;

  AgendaSectionNotifier(this.repository, this.meetingId)
    : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getSections(meetingId);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> createSection(AgendaSectionRequest request) async {
    await repository.createSection(request);
    await load();
  }
}

final agendaItemProvider =
    StateNotifierProvider.family<
      AgendaItemNotifier,
      AsyncValue<List<AgendaItemModel>>,
      int
    >((ref, meetingId) {
      return AgendaItemNotifier(ref.read(agendaRepositoryProvider), meetingId)
        ..load();
    });

class AgendaItemNotifier
    extends StateNotifier<AsyncValue<List<AgendaItemModel>>> {
  final AgendaRepository repository;
  final int meetingId;

  AgendaItemNotifier(this.repository, this.meetingId)
    : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final data = await repository.getItems(meetingId);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> createItem(AgendaItemRequest request) async {
    await repository.createItem(request);
    await load();
  }
}
