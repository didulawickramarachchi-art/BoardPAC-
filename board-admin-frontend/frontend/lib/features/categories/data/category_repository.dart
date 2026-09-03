import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_error_message.dart';
import '../model/category_model.dart';
import '../model/category_request.dart';

class CategoryRepository {
  final Dio dio;

  CategoryRepository(this.dio);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await dio.get('/categories');
      return (response.data as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();
    } catch (error) {
      throw CategoryLoadException(
        ApiErrorMessage.from(error, fallback: 'Unable to load categories.'),
      );
    }
  }

  Future<void> createCategory(CategoryRequest request) async {
    await dio.post('/categories', data: request.toJson());
  }

  Future<void> updateCategory(int categoryId, CategoryRequest request) async {
    await dio.put('/categories/$categoryId', data: request.toJson());
  }

  Future<String> uploadCategoryImage({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    final file = filePath != null && filePath.isNotEmpty
        ? await MultipartFile.fromFile(filePath, filename: fileName)
        : MultipartFile.fromBytes(
            fileBytes ?? Uint8List(0),
            filename: fileName,
          );
    final response = await dio.post(
      ApiConstants.filesUpload,
      data: FormData.fromMap({'file': file}),
    );
    final data = response.data;
    if (data is Map) {
      return (data['filePath'] ?? data['fileUrl'] ?? data['url'] ?? '')
          .toString();
    }
    return data?.toString() ?? '';
  }

  Future<void> deleteCategory(int categoryId) async {
    await dio.delete('/categories/$categoryId');
  }
}

class CategoryLoadException implements Exception {
  final String message;

  const CategoryLoadException(this.message);

  @override
  String toString() => message;
}
