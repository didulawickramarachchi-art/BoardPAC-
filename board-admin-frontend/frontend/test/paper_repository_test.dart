import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/papers/data/paper_repository.dart';

void main() {
  group('PaperRepository upload response parsing', () {
    test('extracts a file path from common upload payload shapes', () {
      final repository = PaperRepository(Dio());

      expect(
        repository.resolveUploadedFilePath({
          'filePath': 'https://cdn.example.com/file.pdf',
        }),
        'https://cdn.example.com/file.pdf',
      );
      expect(
        repository.resolveUploadedFilePath({
          'url': 'https://cdn.example.com/file.png',
        }),
        'https://cdn.example.com/file.png',
      );
      expect(
        repository.resolveUploadedFilePath('https://cdn.example.com/file.jpg'),
        'https://cdn.example.com/file.jpg',
      );
    });
  });
}
