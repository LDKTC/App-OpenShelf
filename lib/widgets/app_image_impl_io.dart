import 'dart:io';

import 'package:flutter/material.dart';

/// Native platforms: render straight from the file on disk, unchanged from
/// how this app always has — same [Image.file] caching behavior.
Widget buildLocalImage(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
