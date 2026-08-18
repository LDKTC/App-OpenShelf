import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'image_path_utils.dart';

/// Copies [file] into the app's local documents directory (under
/// `covers/` or `pages/`) so it persists independently of the picker's
/// often-temporary source file, and returns the saved file's path.
Future<String> saveLocalImage(XFile file, String subfolder, int bookId) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final targetDir = Directory('${docsDir.path}/$subfolder');
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }
  final filename =
      '${bookId}_${DateTime.now().microsecondsSinceEpoch}${_extensionOf(file.name)}';
  final targetPath = '${targetDir.path}/$filename';
  await File(file.path).copy(targetPath);
  return targetPath;
}

String _extensionOf(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot == -1 || dot == filename.length - 1) return '.jpg';
  return filename.substring(dot).toLowerCase();
}

/// Deletes a locally-saved file. A no-op for `null` and for remote paths,
/// since those point at the book's original API thumbnail rather than a
/// file this service owns.
Future<void> deleteLocalImage(String? path) async {
  if (path == null) return;
  if (isRemoteImagePath(path)) return;
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}
