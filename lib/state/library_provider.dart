import 'package:flutter/foundation.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/book_page.dart';
import '../models/category.dart';
import '../models/cover_preset.dart';
import '../models/stamp.dart';
import '../services/database_service.dart';
import '../services/image_storage_service.dart';
import '../services/settings_service.dart';

enum CategoryFilter { all }

/// The reading-status filter chips shown in the library: every [StampType]
/// plus "not started" (a book with no stamps at all). The provider's
/// `statusFilter` being `null` itself means "All" / no filter.
enum LibraryStatusFilter { notStarted, reading, finished, dropped, paused }

extension LibraryStatusFilterX on LibraryStatusFilter {
  String label(AppLocalizations t) => switch (this) {
        LibraryStatusFilter.notStarted => t.statusNotStarted,
        LibraryStatusFilter.reading => t.statusReading,
        LibraryStatusFilter.finished => t.statusFinished,
        LibraryStatusFilter.dropped => t.statusDropped,
        LibraryStatusFilter.paused => t.statusPaused,
      };

  /// The [StampType] a book's current stamp must have to match this
  /// filter, or `null` for [LibraryStatusFilter.notStarted] (no stamps).
  StampType? get stampType => switch (this) {
        LibraryStatusFilter.notStarted => null,
        LibraryStatusFilter.reading => StampType.reading,
        LibraryStatusFilter.finished => StampType.finished,
        LibraryStatusFilter.dropped => StampType.dropped,
        LibraryStatusFilter.paused => StampType.paused,
      };
}

/// Holds the in-memory library state (books, categories, reading-status
/// stamp timelines, cover presets, and saved pages) backed by sqflite, and
/// the current search/filter selections for the library list screen.
class LibraryProvider extends ChangeNotifier {
  LibraryProvider({DatabaseService? db, SettingsService? settings})
      : _db = db ?? DatabaseService.instance,
        _settings = settings ?? SettingsService.instance;

  final DatabaseService _db;
  final SettingsService _settings;

  List<Book> _books = [];
  List<BookCategory> _categories = [];
  Map<int, List<int>> _bookCategoryLinks = {};
  Map<int, List<ReadingStamp>> _stampsByBook = {};
  Map<int, List<BookCoverPreset>> _coverPresetsByBook = {};
  Map<int, List<BookPage>> _pagesByBook = {};
  LibraryViewMode _viewMode = LibraryViewMode.list;
  AppLocale _appLocale = AppLocale.system;

  String _searchQuery = '';
  LibraryStatusFilter? _statusFilter;
  int? _categoryFilterId;
  bool _loading = false;

  List<BookCategory> get categories => List.unmodifiable(_categories);
  String get searchQuery => _searchQuery;
  LibraryStatusFilter? get statusFilter => _statusFilter;
  int? get categoryFilterId => _categoryFilterId;
  bool get loading => _loading;
  LibraryViewMode get viewMode => _viewMode;
  ShelfDisplayMode get shelfDisplayMode => _viewMode.shelfDisplayMode;
  AppLocale get appLocale => _appLocale;

  List<int> categoryIdsFor(int bookId) =>
      List.unmodifiable(_bookCategoryLinks[bookId] ?? const []);

  Book? getById(int id) {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Previously-used field values, for the edit form's suggestion dropdowns
  // ---------------------------------------------------------------------

  Set<String> get knownAuthors => {for (final b in _books) ...b.authors};

  Set<String> get knownIllustrators =>
      {for (final b in _books) ...b.illustrators};

  Set<String> get knownPublishers => {
        for (final b in _books)
          if (b.publisher != null && b.publisher!.isNotEmpty) b.publisher!,
      };

  Set<String> get knownSeries => {
        for (final b in _books)
          if (b.series != null && b.series!.isNotEmpty) b.series!,
      };

  /// The most recent stamp for [bookId] (by timestamp), or null if the
  /// book has no stamps yet — i.e. "not started".
  ReadingStamp? currentStampFor(int bookId) =>
      latestStamp(_stampsByBook[bookId] ?? const []);

  /// All of [bookId]'s stamps, most recent first — the reading-status
  /// timeline shown on the book detail screen.
  List<ReadingStamp> stampsFor(int bookId) {
    final stamps = List<ReadingStamp>.from(_stampsByBook[bookId] ?? const []);
    stamps.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return stamps;
  }

  List<BookCoverPreset> coverPresetsFor(int bookId) =>
      List.unmodifiable(_coverPresetsByBook[bookId] ?? const []);

  /// The preset currently used to render [bookId] on the visual shelf, if
  /// it has any presets at all.
  BookCoverPreset? activeCoverPresetFor(int bookId) {
    final presets = _coverPresetsByBook[bookId];
    if (presets == null) return null;
    for (final preset in presets) {
      if (preset.isActive) return preset;
    }
    return null;
  }

  List<BookPage> pagesFor(int bookId) {
    final pages = List<BookPage>.from(_pagesByBook[bookId] ?? const []);
    pages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pages;
  }

  List<Book> get filteredBooks {
    return _books.where((book) {
      if (_statusFilter != null) {
        final current = currentStampFor(book.id!)?.type;
        if (current != _statusFilter!.stampType) return false;
      }
      if (_categoryFilterId != null) {
        final ids = _bookCategoryLinks[book.id] ?? const [];
        if (!ids.contains(_categoryFilterId)) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final haystack =
            '${book.title} ${book.authorsDisplay} ${book.isbn13 ?? ''}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    _books = await _db.getAllBooks();
    _categories = await _db.getAllCategories();
    _bookCategoryLinks = await _db.getAllBookCategoryLinks();
    _stampsByBook = _groupByBookId(await _db.getAllStamps(), (s) => s.bookId);
    _coverPresetsByBook = _groupByBookId(
      await _db.getAllCoverPresets(),
      (p) => p.bookId,
    );
    _pagesByBook = _groupByBookId(
      await _db.getAllBookPages(),
      (p) => p.bookId,
    );
    _viewMode = await _settings.getLibraryViewMode();
    _appLocale = await _settings.getAppLocale();
    _loading = false;
    notifyListeners();
  }

  Map<int, List<T>> _groupByBookId<T>(
    List<T> items,
    int Function(T) bookIdOf,
  ) {
    final map = <int, List<T>>{};
    for (final item in items) {
      map.putIfAbsent(bookIdOf(item), () => []).add(item);
    }
    return map;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(LibraryStatusFilter? filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _categoryFilterId = categoryId;
    notifyListeners();
  }

  Future<void> setViewMode(LibraryViewMode mode) async {
    _viewMode = mode;
    notifyListeners();
    await _settings.setLibraryViewMode(mode);
  }

  /// Advances the single view-toggle button to the next mode in its cycle
  /// (list -> shelf covers -> shelf spines -> list).
  Future<void> cycleViewMode() => setViewMode(_viewMode.next);

  Future<void> setAppLocale(AppLocale locale) async {
    _appLocale = locale;
    notifyListeners();
    await _settings.setAppLocale(locale);
  }

  Future<Book?> findByIsbn(String isbn13) => _db.findByIsbn(isbn13);

  Future<int> addBook(Book book, {List<int> categoryIds = const []}) async {
    final id = await _db.insertBook(book);
    if (categoryIds.isNotEmpty) {
      await _db.setBookCategories(id, categoryIds);
    }
    await loadAll();
    return id;
  }

  Future<void> updateBook(Book book, {List<int>? categoryIds}) async {
    await _db.updateBook(book);
    if (categoryIds != null && book.id != null) {
      await _db.setBookCategories(book.id!, categoryIds);
    }
    await loadAll();
  }

  Future<void> deleteBook(int id) async {
    await _db.deleteBook(id);
    await loadAll();
  }

  Future<int> addCategory(String name) async {
    final id = await _db.insertCategory(BookCategory(name: name));
    await loadAll();
    return id;
  }

  Future<void> renameCategory(BookCategory category, String newName) async {
    await _db.updateCategory(category.copyWith(name: newName));
    await loadAll();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    if (_categoryFilterId == id) _categoryFilterId = null;
    await loadAll();
  }

  // ---------------------------------------------------------------------
  // Reading stamps
  // ---------------------------------------------------------------------

  Future<void> addStamp(
    int bookId,
    StampType type, {
    DateTime? timestamp,
    String? note,
  }) async {
    await _db.insertStamp(
      ReadingStamp(
        bookId: bookId,
        type: type,
        timestamp: timestamp ?? DateTime.now(),
        note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      ),
    );
    await loadAll();
  }

  Future<void> updateStamp(ReadingStamp stamp) async {
    await _db.updateStamp(stamp);
    await loadAll();
  }

  Future<void> deleteStamp(int stampId) async {
    await _db.deleteStamp(stampId);
    await loadAll();
  }

  // ---------------------------------------------------------------------
  // Cover presets
  // ---------------------------------------------------------------------

  /// Saves a new preset. It becomes the book's active shelf image if it's
  /// the book's first preset, or if the caller explicitly marks it active.
  Future<int> addCoverPreset(BookCoverPreset preset) async {
    final id = await _db.insertCoverPreset(preset);
    final isFirstForBook = coverPresetsFor(preset.bookId).isEmpty;
    if (isFirstForBook || preset.isActive) {
      await _db.setActiveCoverPreset(preset.bookId, id);
    }
    await loadAll();
    return id;
  }

  Future<void> setActiveCoverPreset(int bookId, int presetId) async {
    await _db.setActiveCoverPreset(bookId, presetId);
    await loadAll();
  }

  /// Overwrites an existing preset in place — used when the user comes
  /// back to fill in a slot (front/spine/back) they skipped earlier, or
  /// replaces/removes one that's already there. Which local image files
  /// need saving or deleting is worked out by the caller (the cover scan
  /// screen), since only it knows what actually changed.
  Future<void> updateCoverPreset(BookCoverPreset preset) async {
    await _db.updateCoverPreset(preset);
    await loadAll();
  }

  Future<void> renameCoverPreset(BookCoverPreset preset, String? label) async {
    final trimmed = label?.trim();
    await _db.updateCoverPreset(
      preset.copyWith(
        label: trimmed,
        clearLabel: trimmed == null || trimmed.isEmpty,
      ),
    );
    await loadAll();
  }

  Future<void> deleteCoverPreset(BookCoverPreset preset) async {
    await _db.deleteCoverPreset(preset.id!);
    await ImageStorageService.instance.deleteFile(preset.frontImagePath);
    await ImageStorageService.instance.deleteFile(preset.spineImagePath);
    await ImageStorageService.instance.deleteFile(preset.backImagePath);

    if (preset.isActive) {
      final remaining = coverPresetsFor(
        preset.bookId,
      ).where((p) => p.id != preset.id).toList();
      if (remaining.isNotEmpty) {
        await _db.setActiveCoverPreset(preset.bookId, remaining.first.id!);
      }
    }
    await loadAll();
  }

  // ---------------------------------------------------------------------
  // Saved pages
  // ---------------------------------------------------------------------

  Future<int> addBookPage(BookPage page) async {
    final id = await _db.insertBookPage(page);
    await loadAll();
    return id;
  }

  Future<void> updateBookPage(BookPage page) async {
    await _db.updateBookPage(page);
    await loadAll();
  }

  Future<void> deleteBookPage(BookPage page) async {
    await _db.deleteBookPage(page.id!);
    await ImageStorageService.instance.deleteFile(page.imagePath);
    await loadAll();
  }
}
