import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/database_service.dart';

/// Web: [path] is a `webimg://` key into the local sqlite-in-IndexedDB
/// database (see `local_image_platform_web.dart`) rather than a real file
/// path, so it has to be fetched and shown via [Image.memory] instead of
/// [Image.file].
Widget buildLocalImage(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return FutureBuilder<Uint8List?>(
    future: DatabaseService.instance.getLocalImage(path),
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null) {
        return SizedBox(width: width, height: height);
      }
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    },
  );
}
