import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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

  Future<void> download(
    String url,
    String fileName, {
    required String userName,
    required int userId,
  }) async {
    final previousPath = state.valueOrNull;
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
      final watermarked = await _applyWatermark(
        Uint8List.fromList(bytes),
        userName: userName,
        userId: userId,
      );
      final selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save watermarked board paper',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: watermarked,
      );
      if (selectedPath == null) {
        state = AsyncData(previousPath);
        return;
      }

      // Keep a private copy for offline viewing and annotation. The exported
      // copy remains in the location selected by the user.
      final path = await store.save(paperId, fileName, watermarked);
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

  Future<Uint8List> _applyWatermark(
    Uint8List source, {
    required String userName,
    required int userId,
  }) async {
    final document = PdfDocument(inputBytes: source);
    final logoData = await rootBundle.load('assets/images/slpa_logo.png');
    final logo = PdfBitmap(logoData.buffer.asUint8List());
    final font = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final label = 'SLPA  •  $userName  •  User ID: $userId';

    for (var pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
      final page = document.pages[pageIndex];
      final graphics = page.graphics;
      final pageSize = page.getClientSize();
      graphics.setTransparency(0.13);

      for (double y = 45; y < pageSize.height; y += 105) {
        for (double x = 22; x < pageSize.width; x += 210) {
          graphics.drawImage(logo, Rect.fromLTWH(x, y, 28, 28));
          graphics.drawString(
            label,
            font,
            brush: PdfSolidBrush(PdfColor(18, 39, 91)),
            bounds: Rect.fromLTWH(x + 34, y + 7, 170, 28),
          );
        }
      }
    }

    final output = Uint8List.fromList(await document.save());
    document.dispose();
    return output;
  }

  Future<void> remove() async {
    await store.remove(state.value);
    state = const AsyncData(null);
  }
}
