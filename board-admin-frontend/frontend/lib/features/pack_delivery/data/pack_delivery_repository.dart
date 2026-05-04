import 'package:dio/dio.dart';
import '../model/pack_delivery_model.dart';

class PackDeliveryRepository {
  final Dio dio;

  PackDeliveryRepository(this.dio);

  Future<List<PackDeliveryModel>> getByPaper(int paperId) async {
    final response = await dio.get('/pack-delivery/paper/$paperId');
    return (response.data as List)
        .map((e) => PackDeliveryModel.fromJson(e))
        .toList();
  }

  Future<List<PackDeliveryModel>> getByUser(int userId) async {
    final response = await dio.get('/pack-delivery/user/$userId');
    return (response.data as List)
        .map((e) => PackDeliveryModel.fromJson(e))
        .toList();
  }
}