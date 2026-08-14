import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/book.dart';
import '../models/category.dart';

/// Singleton wrapper around the app's local sqflite database.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static const _dbName = 'openshelf.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            isbn13 TEXT,
            isbn10 TEXT,
            title TEXT NOT NULL,
            authors TEXT,
            publisher TEXT,
            publishedDate TEXT,
            description TEXT,
            pageCount INTEGER,
            thumbnailUrl TEXT,
            language TEXT,
            status TEXT NOT NULL DEFAULT 'unread',
            rating INTEGER,
            notes TEXT,
            source TEXT,
            dateAdded TEXT NOT NULL,
            dateStarted TEXT,
            dateFinished TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_books_isbn13 ON books(isbn13)');

        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            color INTEGER NOT NULL DEFAULT 0xFF6750A4
          )
        ''');

        await db.execute('''
          CREATE TABLE book_categories (
            bookId INTEGER NOT NULL,
            categoryId INTEGER NOT NULL,
            PRIMARY KEY (bookId, categoryId),
            FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE,
            FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE
          )
        ''');

        for (final name in const [
          'Fiction',
          'Non-Fiction',
          'Textbook',
          'Comics & Manga',
        ]) {
          await db.insert('categories', {'name': name, 'color': 0xFF6750A4});
        }
      },
    );
  }

  // ---------------------------------------------------------------------
  // Books
  // ---------------------------------------------------------------------

  Future<int> insertBook(Book book) async {
    final db = await database;
    return db.insert('books', book.toMap());
  }

  Future<int> updateBook(Book book) async {
    final db = await database;
    return db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await database;
    return db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<Book?> getBook(int id) async {
    final db = await database;
    final rows = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  Future<Book?> findByIsbn(String isbn13) async {
    final db = await database;
    final rows = await db.query(
      'books',
      where: 'isbn13 = ?',
      whereArgs: [isbn13],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final rows = await db.query('books', orderBy: 'dateAdded DESC');
    return rows.map(Book.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------

  Future<int> insertCategory(BookCategory category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(BookCategory category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BookCategory>> getAllCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name COLLATE NOCASE');
    return rows.map(BookCategory.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Book <-> Category links
  // ---------------------------------------------------------------------

  Future<void> setBookCategories(int bookId, List<int> categoryIds) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'book_categories',
        where: 'bookId = ?',
        whereArgs: [bookId],
      );
      for (final categoryId in categoryIds) {
        await txn.insert('book_categories', {
          'bookId': bookId,
          'categoryId': categoryId,
        });
      }
    });
  }

  Future<List<int>> getCategoryIdsForBook(int bookId) async {
    final db = await database;
    final rows = await db.query(
      'book_categories',
      columns: ['categoryId'],
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
    return rows.map((r) => r['categoryId'] as int).toList();
  }

  /// Maps every bookId to its set of categoryIds in one query.
  Future<Map<int, List<int>>> getAllBookCategoryLinks() async {
    final db = await database;
    final rows = await db.query('book_categories');
    final map = <int, List<int>>{};
    for (final row in rows) {
      final bookId = row['bookId'] as int;
      final categoryId = row['categoryId'] as int;
      map.putIfAbsent(bookId, () => []).add(categoryId);
    }
    return map;
  }
}
