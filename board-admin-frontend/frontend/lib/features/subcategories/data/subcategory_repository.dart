import 'package:dio/dio.dart';
import '../model/subcategory_model.dart';

class SubcategoryRepository {
  final Dio dio;

  SubcategoryRepository(this.dio);

  Future<List<SubcategoryModel>> getSubcategories() async {
    final response = await dio.get('/subcategories');
    return (response.data as List)
        .map((e) => SubcategoryModel.fromJson(e))
        .toList();
  }
}