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

  Future<void> deleteSection(int sectionId) async {
    await repository.deleteSection(sectionId);
    await load();
  }

  Future<void> reorder(List<AgendaSectionModel> sections) async {
    state = AsyncData(sections);
    try {
      await repository.reorderSections(
        meetingId,
        sections.map((item) => item.id).toList(),
      );
      await load();
    } catch (_) {
      await load();
      rethrow;
    }
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

  Future<void> deleteItem(int itemId) async {
    await repository.deleteItem(itemId);
    await load();
  }

  Future<void> reorder(List<AgendaItemModel> items) async {
    final current = state.value ?? const <AgendaItemModel>[];
    final reorderedIds = items.map((item) => item.id).toSet();
    final merged = <AgendaItemModel>[];
    var inserted = false;
    for (final item in current) {
      if (reorderedIds.contains(item.id)) {
        if (!inserted) {
          merged.addAll(items);
          inserted = true;
        }
      } else {
        merged.add(item);
      }
    }
    state = AsyncData(merged);
    try {
      await repository.reorderItems(
        meetingId,
        items.map((item) => item.id).toList(),
      );
      await load();
    } catch (_) {
      await load();
      rethrow;
    }
  }
}
