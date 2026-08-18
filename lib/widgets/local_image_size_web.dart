import 'dart:ui' as ui;

import '../services/database_service.dart';

/// Web: [path] is a `webimg://` key rather than a file, so decode its
/// dimensions straight from the bytes stored in the local database.
Future<ui.Size?> resolveLocalImageSize(String path) async {
  final bytes = await DatabaseService.instance.getLocalImage(path);
  if (bytes == null) return null;
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble());
}
