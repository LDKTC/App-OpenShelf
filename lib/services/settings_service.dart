import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// The app's display language. [system] follows the device's locale
/// (falling back to English if the device locale isn't supported); the
/// others force a specific language regardless of device locale.
enum AppLocale {
  system,
  english,
  thai;

  String get storageValue => name;

  String label(AppLocalizations t) => switch (this) {
        AppLocale.system => t.localeSystemDefault,
        AppLocale.english => t.localeEnglish,
        AppLocale.thai => t.localeThai,
      };

  /// The [Locale] to pass to [MaterialApp.locale], or null for [system]
  /// (letting Flutter resolve the device's locale against
  /// [MaterialApp.supportedLocales] itself).
  Locale? get locale => switch (this) {
        AppLocale.system => null,
        AppLocale.english => const Locale('en'),
        AppLocale.thai => const Locale('th'),
      };

  static AppLocale fromStorage(String? value) {
    return AppLocale.values.firstWhere(
      (l) => l.storageValue == value,
      orElse: () => AppLocale.system,
    );
  }
}

/// How books render on the visual shelf: as their front cover, or as their
/// spine (each book's active cover preset supplies both images). This is a
/// single app-wide setting, not per-book.
enum ShelfDisplayMode {
  cover,
  spine;

  String get storageValue => name;

  String label(AppLocalizations t) => switch (this) {
        ShelfDisplayMode.cover => t.shelfModeCover,
        ShelfDisplayMode.spine => t.shelfModeSpine,
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
  static const _keyAppLocale = 'app_locale';

  Future<AppLocale> getAppLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLocale.fromStorage(prefs.getString(_keyAppLocale));
  }

  Future<void> setAppLocale(AppLocale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLocale, locale.storageValue);
  }

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
