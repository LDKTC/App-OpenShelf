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
/// spine (each book's active cover preset supplies both images). Derived
/// from [LibraryViewMode] — it's only meaningful for the two shelf modes,
/// but the shelf-rendering widgets only ever care about cover-vs-spine, not
/// whether list view is also in the rotation.
enum ShelfDisplayMode {
  cover,
  spine;

  String label(AppLocalizations t) => switch (this) {
        ShelfDisplayMode.cover => t.shelfModeCover,
        ShelfDisplayMode.spine => t.shelfModeSpine,
      };
}

/// The library screen's single view toggle button cycles through all three
/// of these in order: a flat list, the visual shelf showing front covers,
/// and the visual shelf showing spines.
enum LibraryViewMode {
  list,
  shelfCover,
  shelfSpine;

  String get storageValue => name;

  /// The [ShelfDisplayMode] to render with when this mode is one of the two
  /// shelf modes; meaningless (and unused) for [list].
  ShelfDisplayMode get shelfDisplayMode =>
      this == LibraryViewMode.shelfSpine
          ? ShelfDisplayMode.spine
          : ShelfDisplayMode.cover;

  /// The mode the view-toggle button switches to next.
  LibraryViewMode get next => switch (this) {
        LibraryViewMode.list => LibraryViewMode.shelfCover,
        LibraryViewMode.shelfCover => LibraryViewMode.shelfSpine,
        LibraryViewMode.shelfSpine => LibraryViewMode.list,
      };

  String label(AppLocalizations t) => switch (this) {
        LibraryViewMode.list => t.viewModeListLabel,
        LibraryViewMode.shelfCover => t.viewModeShelfCoverLabel,
        LibraryViewMode.shelfSpine => t.viewModeShelfSpineLabel,
      };

  static LibraryViewMode fromStorage(String? value) {
    return LibraryViewMode.values.firstWhere(
      (m) => m.storageValue == value,
      orElse: () => LibraryViewMode.list,
    );
  }
}

/// How the library list/shelf orders its books. [dateAdded] (the default)
/// matches the database's natural insertion order; the rest sort
/// alphabetically/numerically over the matching [Book] field.
enum LibrarySortField {
  dateAdded,
  title,
  series,
  author,
  publisher,
  isbn,
  languageGenre;

  String get storageValue => name;

  String label(AppLocalizations t) => switch (this) {
        LibrarySortField.dateAdded => t.sortByDateAdded,
        LibrarySortField.title => t.titleField,
        LibrarySortField.series => t.seriesField,
        LibrarySortField.author => t.sortByAuthor,
        LibrarySortField.publisher => t.publisherField,
        LibrarySortField.isbn => t.isbn13Field,
        LibrarySortField.languageGenre => t.sortByLanguageGenre,
      };

  static LibrarySortField fromStorage(String? value) {
    return LibrarySortField.values.firstWhere(
      (f) => f.storageValue == value,
      orElse: () => LibrarySortField.dateAdded,
    );
  }
}

/// Persists user-configurable app settings: the optional Cloud Vision API
/// key used for OCR text scanning, and the library view mode.
class SettingsService {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  static const _keyLibraryViewMode = 'library_view_mode';
  static const _keyLibrarySortField = 'library_sort_field';
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

  Future<LibraryViewMode> getLibraryViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return LibraryViewMode.fromStorage(prefs.getString(_keyLibraryViewMode));
  }

  Future<void> setLibraryViewMode(LibraryViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLibraryViewMode, mode.storageValue);
  }

  Future<LibrarySortField> getLibrarySortField() async {
    final prefs = await SharedPreferences.getInstance();
    return LibrarySortField.fromStorage(prefs.getString(_keyLibrarySortField));
  }

  Future<void> setLibrarySortField(LibrarySortField field) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLibrarySortField, field.storageValue);
  }
}
