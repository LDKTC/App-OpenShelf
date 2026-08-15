import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Whether [path] is a remote URL (e.g. a book's API thumbnail, promoted
/// straight into a cover preset slot) rather than a local file path saved
/// by [ImageStorageService].
bool isRemoteImagePath(String path) =>
    path.startsWith('http://') || path.startsWith('https://');

/// Copies photos captured/picked via [ImagePicker] into the app's local
/// documents directory (under `covers/` or `pages/`) so they persist
/// independently of the picker's often-temporary source file, and removes
/// them again when a preset/page is deleted or an image slot is retaken.
class ImageStorageService {
  ImageStorageService._();
  static final ImageStorageService instance = ImageStorageService._();

  Future<String> saveCoverImage(int bookId, XFile file) =>
      _save(file, 'covers', bookId);

  Future<String> savePageImage(int bookId, XFile file) =>
      _save(file, 'pages', bookId);

  Future<String> _save(XFile file, String subfolder, int bookId) async {
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

  /// Deletes a locally-stored image. A no-op for `null` and for
  /// `http(s)://` paths, since those point at the book's original API
  /// thumbnail rather than a file this service owns.
  Future<void> deleteFile(String? path) async {
    if (path == null) return;
    if (isRemoteImagePath(path)) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
