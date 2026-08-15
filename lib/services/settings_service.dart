import 'package:shared_preferences/shared_preferences.dart';

/// How books render on the visual shelf: as their front cover, or as their
/// spine (each book's active cover preset supplies both images). This is a
/// single app-wide setting, not per-book.
enum ShelfDisplayMode {
  cover,
  spine;

  String get storageValue => name;

  String get label => switch (this) {
        ShelfDisplayMode.cover => 'Cover',
        ShelfDisplayMode.spine => 'Spine',
      };

  static ShelfDisplayMode fromStorage(String? value) {
    return ShelfDisplayMode.values.firstWhere(
      (m) => m.storageValue == value,
      orElse: () => ShelfDisplayMode.cover,
    );
  }
}

/// Persists user-configurable app settings: the optional Cloud Vision API
/// key used for OCR text scanning, and the shelf display mode.
class SettingsService {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  static const _keyShelfDisplayMode = 'shelf_display_mode';
  static const _keyCloudVisionApiKey = 'cloud_vision_api_key';

  /// Google Cloud Vision API key used for OCR text scanning (title, author,
  /// illustrator, ISBN, publisher). Optional: when unset, OCR scans fall
  /// back to on-device ML Kit text recognition, which is free and offline
  /// but only reads Latin-script text — Cloud Vision also reads Thai.
  Future<String?> getCloudVisionApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCloudVisionApiKey);
  }

  Future<void> setCloudVisionApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.trim().isEmpty) {
      await prefs.remove(_keyCloudVisionApiKey);
    } else {
      await prefs.setString(_keyCloudVisionApiKey, key.trim());
    }
  }

  Future<ShelfDisplayMode> getShelfDisplayMode() async {
    final prefs = await SharedPreferences.getInstance();
    return ShelfDisplayMode.fromStorage(prefs.getString(_keyShelfDisplayMode));
  }

  Future<void> setShelfDisplayMode(ShelfDisplayMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyShelfDisplayMode, mode.storageValue);
  }
}
