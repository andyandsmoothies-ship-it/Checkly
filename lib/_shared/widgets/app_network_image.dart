import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/auth/manager/auth_manager.dart';
import '../../locator.dart';
import '../services/api_client.dart';

/// A universal image widget that intelligently routes image rendering based on
/// the URL scheme. It resolves relative server paths (e.g. `/api/photos/123.jpg`)
/// using the injected `ApiClient` base URL, ensuring the app does not crash
/// when attempting to load server photos from the local file system.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('/api')) {
      // It's a relative server URL — prepend the active base URL
      final baseUrl = di<ApiClient>().dio.options.baseUrl;
      final base = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

      String absoluteUrl;
      if (base.endsWith('/api') && url.startsWith('/api')) {
        // Strip the trailing /api from base before appending the url
        absoluteUrl = '${base.substring(0, base.length - 4)}$url';
      } else {
        absoluteUrl = '$base$url';
      }

      final token = di<AuthManager>().currentUser?.token;

      return Image.network(
        absoluteUrl,
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    } else if (url.startsWith('http')) {
      // It's already an absolute URL
      return Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    } else {
      // It's a local filesystem path (e.g., from ImagePicker offline)
      return Image.file(
        File(url),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
  }
}
