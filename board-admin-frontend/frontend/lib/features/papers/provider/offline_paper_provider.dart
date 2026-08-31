import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/offline_file_store.dart';

final offlineFileStoreProvider = Provider((_) => OfflineFileStore());
final offlinePaperProvider =
    StateNotifierProvider.family<
      OfflinePaperNotifier,
      AsyncValue<String?>,
      int
    >(
      (ref, id) => OfflinePaperNotifier(
        id,
        ref.read(dioProvider),
        ref.read(offlineFileStoreProvider),
      ),
    );

class OfflinePaperNotifier extends StateNotifier<AsyncValue<String?>> {
  final int paperId;
  final Dio dio;
  final OfflineFileStore store;
  OfflinePaperNotifier(this.paperId, this.dio, this.store)
    : super(const AsyncData(null));
  bool _initialized = false;
  Future<void> initialize(String fileName) async {
    if (_initialized) return;
    _initialized = true;
    final path = await store.localPath(paperId, fileName);
    if (mounted) state = AsyncData(path);
  }

  Future<void> download(String url, String fileName) async {
    state = const AsyncLoading();
    try {
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final path = await store.save(
        paperId,
        fileName,
        Uint8List.fromList(response.data!),
      );
      if (path == null) {
        throw UnsupportedError(
          'Offline downloads are not available on this platform',
        );
      }
      await dio.post('/pack-delivery/paper/$paperId/downloaded');
      state = AsyncData(path);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> remove() async {
    await store.remove(state.value);
    state = const AsyncData(null);
  }
}
