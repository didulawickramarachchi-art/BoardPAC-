import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'get_cache_interceptor.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(seconds: 45),
      persistentConnection: true,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Free ngrok tunnels otherwise return an HTML browser interstitial
        // instead of forwarding API requests to the backend.
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  dio.interceptors.addAll([AuthInterceptor(storage), GetCacheInterceptor()]);

  return dio;
});
