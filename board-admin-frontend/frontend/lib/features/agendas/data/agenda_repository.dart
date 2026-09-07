import 'package:dio/dio.dart';
import '../model/agenda_item_model.dart';
import '../model/agenda_item_request.dart';
import '../model/agenda_section_model.dart';
import '../model/agenda_section_request.dart';

class AgendaRepository {
  final Dio dio;

  AgendaRepository(this.dio);

  Future<List<AgendaSectionModel>> getSections(int meetingId) async {
    final response = await dio.get('/agendas/sections/$meetingId');
    return (response.data as List)
        .map((e) => AgendaSectionModel.fromJson(e))
        .toList();
  }

  Future<void> createSection(AgendaSectionRequest request) async {
    await dio.post('/agendas/sections', data: request.toJson());
  }

  Future<void> deleteSection(int sectionId) async {
    await dio.delete('/agendas/sections/$sectionId');
  }

  Future<void> reorderSections(int meetingId, List<int> orderedIds) async {
    await dio.put(
      '/agendas/sections/$meetingId/order',
      data: {'orderedIds': orderedIds},
    );
  }

  Future<List<AgendaItemModel>> getItems(int meetingId) async {
    final response = await dio.get('/agendas/items/$meetingId');
    return (response.data as List)
        .map((e) => AgendaItemModel.fromJson(e))
        .toList();
  }

  Future<void> createItem(AgendaItemRequest request) async {
    await dio.post('/agendas/items', data: request.toJson());
  }

  Future<void> deleteItem(int itemId) async {
    await dio.delete('/agendas/items/$itemId');
  }

  Future<void> reorderItems(int meetingId, List<int> orderedIds) async {
    await dio.put(
      '/agendas/items/$meetingId/order',
      data: {'orderedIds': orderedIds},
    );
  }
}
