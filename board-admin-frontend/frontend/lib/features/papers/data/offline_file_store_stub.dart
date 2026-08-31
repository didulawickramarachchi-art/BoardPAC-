import 'dart:typed_data';

class OfflineFileStore {
  Future<String?> save(int paperId, String fileName, Uint8List bytes) async =>
      null;
  Future<Uint8List?> read(String path) async => null;
  Future<bool> exists(String? path) async => false;
  Future<String?> localPath(int paperId, String fileName) async => null;
  Future<void> remove(String? path) async {}
}
