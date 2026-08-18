import 'package:image_picker/image_picker.dart';

import 'database_service.dart';
import 'image_path_utils.dart';

const _keyPrefix = 'webimg://';

/// Web has no filesystem, so a "saved" image is just its bytes persisted in
/// the [DatabaseService]'s `local_images` table (itself backed by the
/// browser's IndexedDB), keyed by a synthetic `webimg://` path that stands
/// in for the file path a native save would have returned.
Future<String> saveLocalImage(XFile file, String subfolder, int bookId) async {
  final bytes = await file.readAsBytes();
  final key =
      '$_keyPrefix$subfolder/${bookId}_${DateTime.now().microsecondsSinceEpoch}';
  await DatabaseService.instance.putLocalImage(key, bytes);
  return key;
}

/// Deletes a locally-saved image's bytes. A no-op for `null`, remote paths,
/// and paths that were never a `webimg://` key (nothing else is ours to
/// delete on web).
Future<void> deleteLocalImage(String? path) async {
  if (path == null) return;
  if (isRemoteImagePath(path)) return;
  if (!path.startsWith(_keyPrefix)) return;
  await DatabaseService.instance.deleteLocalImage(path);
}
