import 'package:dio/dio.dart';
import '../model/device_model.dart';

class DeviceRepository {
  final Dio dio;

  DeviceRepository(this.dio);

  Future<List<DeviceModel>> getDevices() async {
    final response = await dio.get('/devices');
    return (response.data as List)
        .map((e) => DeviceModel.fromJson(e))
        .toList();
  }

  Future<void> approveDevice(int id) async {
    await dio.put('/devices/$id/approve');
  }

  Future<void> deactivateDevice(int id) async {
    await dio.put('/devices/$id/deactivate');
  }

  Future<void> wipeDevice(int id) async {
    await dio.put('/devices/$id/wipe');
  }
}