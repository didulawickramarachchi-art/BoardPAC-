import 'package:dio/dio.dart';

/// A small session cache for read-only API requests.
///
/// Screens can be reopened without downloading the same lists again. Any API
/// write clears the cache, so subsequent reads cannot return pre-mutation data.
class GetCacheInterceptor extends Interceptor {
  GetCacheInterceptor({
    this.timeToLive = const Duration(minutes: 2),
    this.maximumEntries = 100,
  });

  final Duration timeToLive;
  final int maximumEntries;
  final Map<String, _CacheEntry> _entries = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      _entries.clear();
      handler.next(options);
      return;
    }

    if (!_isCacheable(options)) {
      handler.next(options);
      return;
    }

    final key = _keyFor(options);
    final cached = _entries[key];
    if (cached == null ||
        DateTime.now().difference(cached.savedAt) > timeToLive) {
      _entries.remove(key);
      handler.next(options);
      return;
    }

    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        data: cached.data,
        statusCode: cached.statusCode,
        statusMessage: cached.statusMessage,
        headers: Headers.fromMap(cached.headers),
        extra: const {'servedFromMemoryCache': true},
      ),
    );
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final request = response.requestOptions;
    if (_isCacheable(request) &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      if (_entries.length >= maximumEntries) {
        _entries.remove(_entries.keys.first);
      }
      _entries[_keyFor(request)] = _CacheEntry(
        savedAt: DateTime.now(),
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers.map,
      );
    }
    handler.next(response);
  }

  bool _isCacheable(RequestOptions options) =>
      options.method.toUpperCase() == 'GET' &&
      options.extra['skipMemoryCache'] != true &&
      !options.path.contains('/notifications');

  String _keyFor(RequestOptions options) {
    // Account-specific responses must never be shared between login sessions.
    final authorization = options.headers['Authorization']?.toString() ?? '';
    return '${authorization.hashCode}:${options.uri}';
  }
}

class _CacheEntry {
  const _CacheEntry({
    required this.savedAt,
    required this.data,
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
  });

  final DateTime savedAt;
  final dynamic data;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, List<String>> headers;
}
