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
      final uri = Uri.tryParse(url);
      final isExternalUrl =
          uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
      final downloadClient = isExternalUrl
          ? Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 2),
                sendTimeout: const Duration(seconds: 30),
              ),
            )
          : dio;
      final response = await downloadClient.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('The downloaded paper is empty');
      }
      final path = await store.save(
        paperId,
        fileName,
        Uint8List.fromList(bytes),
      );
      if (path == null) {
        throw UnsupportedError(
          'Offline downloads are not available on this platform',
        );
      }
      state = AsyncData(path);

      // Delivery tracking must not invalidate a file that was already saved.
      try {
        await dio.post('/pack-delivery/paper/$paperId/downloaded');
      } on DioException {
        // The next successful interaction can update server-side tracking.
      }
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> remove() async {
    await store.remove(state.value);
    state = const AsyncData(null);
  }
}
