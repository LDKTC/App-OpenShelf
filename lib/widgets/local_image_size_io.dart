import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

/// Native: resolves the file's intrinsic pixel size via [FileImage], same
/// as this app always has.
Future<Size?> resolveLocalImageSize(String path) {
  final provider = FileImage(File(path));
  final completer = Completer<Size?>();
  final stream = provider.resolve(const ImageConfiguration());
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      final size = Size(info.image.width.toDouble(), info.image.height.toDouble());
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(size);
    },
    onError: (error, stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(null);
    },
  );
  stream.addListener(listener);
  return completer.future;
}
