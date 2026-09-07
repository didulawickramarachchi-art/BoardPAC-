import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../model/news_post.dart';

class NewsRepository {
  final Dio dio;
  NewsRepository(this.dio);
  Future<List<NewsPost>> getAll() async {
    final r = await dio.get('/news');
    return (r.data as List)
        .whereType<Map<String, dynamic>>()
        .map(NewsPost.fromJson)
        .toList();
  }

  Future<String> uploadPhoto(Uint8List bytes, String fileName) async {
    final response = await dio.post(
      '/files/upload',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data;
    return data is Map ? (data['filePath'] ?? '').toString() : '';
  }

  Future<NewsPost> create(
    String title,
    String content,
    List<String> imageUrls,
  ) async => NewsPost.fromJson(
    Map<String, dynamic>.from(
      (await dio.post(
        '/news',
        data: {'title': title, 'content': content, 'imageUrls': imageUrls},
      )).data,
    ),
  );
  Future<NewsPost> update(
    int id,
    String title,
    String content,
    List<String> imageUrls,
  ) async => NewsPost.fromJson(
    Map<String, dynamic>.from(
      (await dio.put(
        '/news/$id',
        data: {'title': title, 'content': content, 'imageUrls': imageUrls},
      )).data,
    ),
  );
  Future<void> delete(int id) async => dio.delete('/news/$id');
  Future<void> reorder(List<int> ids) async =>
      dio.put('/news/order', data: {'orderedIds': ids});
  Future<NewsPost> comment(int id, String message) async => NewsPost.fromJson(
    Map<String, dynamic>.from(
      (await dio.post('/news/$id/comments', data: {'message': message})).data,
    ),
  );
  Future<NewsPost> react(int id, String type) async => NewsPost.fromJson(
    Map<String, dynamic>.from(
      (await dio.post(
        '/news/$id/reactions',
        data: {'reactionType': type},
      )).data,
    ),
  );
}
