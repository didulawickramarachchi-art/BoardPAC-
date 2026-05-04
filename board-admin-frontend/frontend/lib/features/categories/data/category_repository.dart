import 'package:dio/dio.dart';
import '../model/category_model.dart';

class CategoryRepository {
  final Dio dio;

  CategoryRepository(this.dio);

  Future<List<CategoryModel>> getCategories() async {
    final response = await dio.get('/categories');
    return (response.data as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
  }
}