import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/book.dart';
import '../models/book_page.dart';
import '../models/category.dart';
import '../models/cover_preset.dart';
import '../models/stamp.dart';

/// Singleton wrapper around the app's local sqflite database.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static const _dbName = 'quetzalib.db';
  static const _dbVersion = 2;

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
            rating INTEGER,
            notes TEXT,
            source TEXT,
            dateAdded TEXT NOT NULL
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

        await _createStatusScanTables(db);

        for (final name in const [
          'Fiction',
          'Non-Fiction',
          'Textbook',
          'Comics & Manga',
        ]) {
          await db.insert('categories', {'name': name, 'color': 0xFF6750A4});
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToV2(db);
        }
      },
    );
  }

  /// Creates the reading-stamps/cover-presets/saved-pages tables shared by
  /// fresh installs ([onCreate]) and upgrades ([_migrateToV2]). Takes a
  /// [DatabaseExecutor] rather than [Database] so it can run either
  /// directly or inside the transaction used by [_migrateToV2].
  Future<void> _createStatusScanTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE reading_stamps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_reading_stamps_bookId ON reading_stamps(bookId)',
    );

    await db.execute('''
      CREATE TABLE book_cover_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        label TEXT,
        frontImagePath TEXT,
        spineImagePath TEXT,
        backImagePath TEXT,
        isActive INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_book_cover_presets_bookId ON book_cover_presets(bookId)',
    );

    await db.execute('''
      CREATE TABLE book_pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        pageLabel TEXT,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_book_pages_bookId ON book_pages(bookId)',
    );
  }

  /// Upgrades a v1 database (single `status`/`dateStarted`/`dateFinished`
  /// columns on `books`) to v2 (a `reading_stamps` timeline, plus the new
  /// cover-preset and saved-page tables).
  ///
  /// The old columns are intentionally left in place on `books` rather than
  /// dropped: `ALTER TABLE ... DROP COLUMN` needs SQLite 3.35+, which isn't
  /// guaranteed to be available on every Android version this app runs on,
  /// and rebuilding the table via rename-and-recreate risks corrupting the
  /// `book_categories` foreign key (SQLite rewrites FK references on
  /// `RENAME TABLE`). Leaving a few unused, never-again-written columns
  /// behind is harmless and far safer. [Book.toMap]/[Book.fromMap] no
  /// longer read or write them.
  Future<void> _migrateToV2(Database db) async {
    await db.transaction((txn) async {
      // Tables must exist before the backfill below can insert into
      // reading_stamps.
      await _createStatusScanTables(txn);

      final oldRows = await txn.query(
        'books',
        columns: ['id', 'status', 'dateStarted', 'dateFinished', 'dateAdded'],
      );
      for (final row in oldRows) {
        final bookId = row['id'] as int;
        final status = row['status'] as String?;
        final dateStarted = row['dateStarted'] as String?;
        final dateFinished = row['dateFinished'] as String?;
        final dateAdded = row['dateAdded'] as String;

        if (dateStarted != null) {
          await txn.insert('reading_stamps', {
            'bookId': bookId,
            'type': StampType.reading.storageValue,
            'timestamp': dateStarted,
          });
        }
        if (status == 'read') {
          await txn.insert('reading_stamps', {
            'bookId': bookId,
            'type': StampType.finished.storageValue,
            'timestamp': dateFinished ?? dateStarted ?? dateAdded,
          });
        } else if (status == 'reading' && dateStarted == null) {
          await txn.insert('reading_stamps', {
            'bookId': bookId,
            'type': StampType.reading.storageValue,
            'timestamp': dateAdded,
          });
        }
      }
    });
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

  // ---------------------------------------------------------------------
  // Reading stamps
  // ---------------------------------------------------------------------

  Future<int> insertStamp(ReadingStamp stamp) async {
    final db = await database;
    return db.insert('reading_stamps', stamp.toMap());
  }

  Future<int> updateStamp(ReadingStamp stamp) async {
    final db = await database;
    return db.update(
      'reading_stamps',
      stamp.toMap(),
      where: 'id = ?',
      whereArgs: [stamp.id],
    );
  }

  Future<int> deleteStamp(int id) async {
    final db = await database;
    return db.delete('reading_stamps', where: 'id = ?', whereArgs: [id]);
  }

  /// Every stamp for every book in one query; [LibraryProvider] groups
  /// these by bookId the same way it already does for category links.
  Future<List<ReadingStamp>> getAllStamps() async {
    final db = await database;
    final rows = await db.query('reading_stamps', orderBy: 'timestamp DESC');
    return rows.map(ReadingStamp.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Cover presets
  // ---------------------------------------------------------------------

  Future<int> insertCoverPreset(BookCoverPreset preset) async {
    final db = await database;
    return db.insert('book_cover_presets', preset.toMap());
  }

  Future<int> updateCoverPreset(BookCoverPreset preset) async {
    final db = await database;
    return db.update(
      'book_cover_presets',
      preset.toMap(),
      where: 'id = ?',
      whereArgs: [preset.id],
    );
  }

  Future<int> deleteCoverPreset(int id) async {
    final db = await database;
    return db.delete('book_cover_presets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BookCoverPreset>> getAllCoverPresets() async {
    final db = await database;
    final rows = await db.query(
      'book_cover_presets',
      orderBy: 'createdAt DESC',
    );
    return rows.map(BookCoverPreset.fromMap).toList();
  }

  /// Marks [presetId] as the active preset for [bookId] and clears the
  /// flag on any of that book's other presets.
  Future<void> setActiveCoverPreset(int bookId, int presetId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'book_cover_presets',
        {'isActive': 0},
        where: 'bookId = ?',
        whereArgs: [bookId],
      );
      await txn.update(
        'book_cover_presets',
        {'isActive': 1},
        where: 'id = ?',
        whereArgs: [presetId],
      );
    });
  }

  // ---------------------------------------------------------------------
  // Saved pages
  // ---------------------------------------------------------------------

  Future<int> insertBookPage(BookPage page) async {
    final db = await database;
    return db.insert('book_pages', page.toMap());
  }

  Future<int> updateBookPage(BookPage page) async {
    final db = await database;
    return db.update(
      'book_pages',
      page.toMap(),
      where: 'id = ?',
      whereArgs: [page.id],
    );
  }

  Future<int> deleteBookPage(int id) async {
    final db = await database;
    return db.delete('book_pages', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BookPage>> getAllBookPages() async {
    final db = await database;
    final rows = await db.query('book_pages', orderBy: 'createdAt DESC');
    return rows.map(BookPage.fromMap).toList();
  }
}
