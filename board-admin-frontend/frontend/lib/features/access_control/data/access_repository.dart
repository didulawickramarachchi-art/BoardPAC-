import 'package:dio/dio.dart';
import '../model/access_validation_model.dart';

class AccessRepository {
  final Dio dio;

  AccessRepository(this.dio);

  Future<AccessValidationModel> validate({
    required int userId,
    required String channel,
  }) async {
    final response = await dio.get(
      '/access-control/validate/$userId',
      queryParameters: {'channel': channel},
    );
    return AccessValidationModel.fromJson(response.data);
  }
}