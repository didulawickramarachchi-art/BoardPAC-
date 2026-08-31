import 'package:dio/dio.dart';
import '../model/favorite_model.dart';

class FavoriteRepository {
  final Dio dio;
  FavoriteRepository(this.dio);

  Future<List<FavoriteModel>> getAll() async {
    final response = await dio.get('/favorites');
    return (response.data as List)
        .map((item) => FavoriteModel.fromJson(item))
        .toList();
  }

  Future<void> add(String type, int targetId) =>
      dio.put('/favorites/$type/$targetId');

  Future<void> remove(String type, int targetId) =>
      dio.delete('/favorites/$type/$targetId');
}
