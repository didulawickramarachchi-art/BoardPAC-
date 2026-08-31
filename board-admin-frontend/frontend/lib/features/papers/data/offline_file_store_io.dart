import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class OfflineFileStore {
  Future<Directory> _folder() async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory('${root.path}${Platform.pathSeparator}boardpacks');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  Future<String?> save(int paperId, String fileName, Uint8List bytes) async {
    final folder = await _folder();
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final file = File(
      '${folder.path}${Platform.pathSeparator}${paperId}_$safe',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Uint8List?> read(String path) async {
    final f = File(path);
    return await f.exists() ? f.readAsBytes() : null;
  }

  Future<bool> exists(String? path) async =>
      path != null && await File(path).exists();
  Future<String?> localPath(int paperId, String fileName) async {
    final folder = await _folder();
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '${folder.path}${Platform.pathSeparator}${paperId}_$safe';
    return await File(path).exists() ? path : null;
  }

  Future<void> remove(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
