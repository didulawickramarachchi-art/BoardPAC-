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

  Future<List<AgendaItemModel>> getItems(int meetingId) async {
    final response = await dio.get('/agendas/items/$meetingId');
    return (response.data as List)
        .map((e) => AgendaItemModel.fromJson(e))
        .toList();
  }

  Future<void> createItem(AgendaItemRequest request) async {
    await dio.post('/agendas/items', data: request.toJson());
  }
}
