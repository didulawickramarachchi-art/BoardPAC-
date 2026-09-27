import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

/// Loads API-hosted images with the current access token.
///
/// File URLs are normalized to the configured API host because the backend may
/// have persisted an absolute URL created by a different client (for example,
/// localhost from the web app, which is unreachable from Android emulators).
class AppNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit? fit;
  final int? cacheWidth;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final ImageErrorWidgetBuilder? errorBuilder;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit,
    this.cacheWidth,
    this.filterQuality = FilterQuality.low,
    this.gaplessPlayback = false,
    this.errorBuilder,
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  late final Future<String?> _token = SecureStorageService().getAccessToken();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _token,
      builder: (context, snapshot) {
        final token = snapshot.data;
        return Image.network(
          _normalizeApiFileUrl(widget.url),
          fit: widget.fit,
          cacheWidth: widget.cacheWidth,
          filterQuality: widget.filterQuality,
          gaplessPlayback: widget.gaplessPlayback,
          headers: {
            'ngrok-skip-browser-warning': 'true',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          errorBuilder: widget.errorBuilder,
        );
      },
    );
  }

  String _normalizeApiFileUrl(String value) {
    final imageUri = Uri.tryParse(value.trim());
    if (imageUri == null || !imageUri.path.startsWith('/api/files/')) {
      return value.trim();
    }

    final apiUri = Uri.tryParse(ApiConstants.baseUrl);
    if (apiUri == null || !apiUri.hasScheme || apiUri.host.isEmpty) {
      return value.trim();
    }

    return apiUri
        .replace(
          path: imageUri.path,
          query: imageUri.hasQuery ? imageUri.query : null,
          fragment: imageUri.hasFragment ? imageUri.fragment : null,
        )
        .toString();
  }
}
