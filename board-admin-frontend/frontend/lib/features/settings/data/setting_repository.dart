import 'package:dio/dio.dart';
import '../model/setting_model.dart';
import '../model/setting_request.dart';

class SettingRepository {
  final Dio dio;

  SettingRepository(this.dio);

  Future<List<SettingModel>> getAll() async {
    final response = await dio.get('/settings');
    return (response.data as List)
        .map((e) => SettingModel.fromJson(e))
        .toList();
  }

  Future<List<SettingModel>> getByGroup(String group) async {
    final response = await dio.get('/settings/group/$group');
    return (response.data as List)
        .map((e) => SettingModel.fromJson(e))
        .toList();
  }

  Future<void> save(SettingRequest request) async {
    await dio.post('/settings', data: request.toJson());
  }
}
