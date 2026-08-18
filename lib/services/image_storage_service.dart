import 'package:image_picker/image_picker.dart';

import 'local_image_platform.dart';

export 'image_path_utils.dart';

/// Persists photos captured/picked via [ImagePicker] into local storage so
/// they outlive the picker's often-temporary source file, and removes them
/// again when a preset/page is deleted or an image slot is retaken.
///
/// On native platforms this copies the file into the app's documents
/// directory; on web (no filesystem) it saves the bytes into the local
/// sqlite-in-IndexedDB database instead — see [local_image_platform.dart].
class ImageStorageService {
  ImageStorageService._();
  static final ImageStorageService instance = ImageStorageService._();

  Future<String> saveCoverImage(int bookId, XFile file) =>
      saveLocalImage(file, 'covers', bookId);

  Future<String> savePageImage(int bookId, XFile file) =>
      saveLocalImage(file, 'pages', bookId);

  Future<void> deleteFile(String? path) => deleteLocalImage(path);
}
