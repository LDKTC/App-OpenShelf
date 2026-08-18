import 'package:flutter/material.dart';

import '../services/image_path_utils.dart';
import 'app_image_impl_web.dart' if (dart.library.io) 'app_image_impl_io.dart'
    as impl;

/// Renders a book's cover/spine/back/page photo, whether it's a remote API
/// thumbnail, a locally-saved native file, or (on web) bytes saved into the
/// local IndexedDB-backed database — callers pass the same `path` string
/// [Book]/[BookCoverPreset]/[BookPage] already store and don't need to know
/// which of those it resolves to.
class AppImage extends StatelessWidget {
  const AppImage(
    this.path, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String path;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (isRemoteImagePath(path)) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }
    return impl.buildLocalImage(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
}
