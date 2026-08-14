import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/category.dart';
import '../models/read_status.dart';
import '../services/database_service.dart';

enum CategoryFilter { all }

/// Holds the in-memory library state (books + categories) backed by
/// sqflite, and the current search/filter selections for the library
/// list screen.
class LibraryProvider extends ChangeNotifier {
  LibraryProvider({DatabaseService? db})
      : _db = db ?? DatabaseService.instance;

  final DatabaseService _db;

  List<Book> _books = [];
  List<BookCategory> _categories = [];
  Map<int, List<int>> _bookCategoryLinks = {};

  String _searchQuery = '';
  ReadStatus? _statusFilter;
  int? _categoryFilterId;
  bool _loading = false;

  List<BookCategory> get categories => List.unmodifiable(_categories);
  String get searchQuery => _searchQuery;
  ReadStatus? get statusFilter => _statusFilter;
  int? get categoryFilterId => _categoryFilterId;
  bool get loading => _loading;

  List<int> categoryIdsFor(int bookId) =>
      List.unmodifiable(_bookCategoryLinks[bookId] ?? const []);

  Book? getById(int id) {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  List<Book> get filteredBooks {
    return _books.where((book) {
      if (_statusFilter != null && book.status != _statusFilter) {
        return false;
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
    _loading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(ReadStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _categoryFilterId = categoryId;
    notifyListeners();
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

  Future<void> setStatus(Book book, ReadStatus status) async {
    final now = DateTime.now();
    final updated = book.copyWith(
      status: status,
      dateStarted: status == ReadStatus.reading && book.dateStarted == null
          ? now
          : null,
      dateFinished: status == ReadStatus.read ? now : null,
      clearDateFinished: status != ReadStatus.read,
    );
    await updateBook(updated);
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
}
