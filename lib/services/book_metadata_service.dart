import '../models/book_metadata.dart';
import 'isbn_utils.dart';
import 'metadata_providers/google_books_provider.dart';
import 'metadata_providers/open_library_provider.dart';
import 'metadata_providers/ranobedb_provider.dart';

/// Orchestrates ISBN metadata lookup across providers.
///
/// RanobeDB (light novels) is tried last: its API has no direct ISBN
/// search, so it rarely matches for non-light-novel books. Any provider
/// that fails (network error, no match, not yet configured) is skipped
/// silently and the next one is tried.
class BookMetadataService {
  BookMetadataService({
    GoogleBooksProvider? googleBooks,
    OpenLibraryProvider? openLibrary,
    RanobeDbProvider? ranobeDb,
  })  : _googleBooks = googleBooks ?? GoogleBooksProvider(),
        _openLibrary = openLibrary ?? OpenLibraryProvider(),
        _ranobeDb = ranobeDb ?? RanobeDbProvider();

  final GoogleBooksProvider _googleBooks;
  final OpenLibraryProvider _openLibrary;
  final RanobeDbProvider _ranobeDb;

  /// Returns metadata for [rawIsbn], or null if no provider had a match
  /// or the barcode isn't a valid ISBN.
  Future<BookMetadata?> lookup(String rawIsbn) async {
    final isbn13 = IsbnUtils.normalizeToIsbn13(rawIsbn);
    if (isbn13 == null) return null;

    final providers = [
      _googleBooks.lookup,
      _openLibrary.lookup,
      _ranobeDb.lookup,
    ];

    for (final provider in providers) {
      try {
        final result = await provider(isbn13);
        if (result != null) return result;
      } catch (_) {
        // Try the next provider.
      }
    }
    return null;
  }
}
