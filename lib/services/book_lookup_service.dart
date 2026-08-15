import '../models/book.dart';
import '../models/book_metadata.dart';
import '../state/library_provider.dart';
import 'book_metadata_service.dart';
import 'isbn_utils.dart';

/// Outcome of resolving a raw ISBN string (scanned or typed) against the
/// local library and, failing that, the metadata providers.
sealed class IsbnLookupResult {
  const IsbnLookupResult();
}

/// [rawIsbn] wasn't a valid ISBN-10/13 at all.
class IsbnLookupInvalid extends IsbnLookupResult {
  const IsbnLookupInvalid();
}

/// The ISBN already matches a book already in the library.
class IsbnLookupExisting extends IsbnLookupResult {
  const IsbnLookupExisting(this.book);
  final Book book;
}

/// No local match, but a metadata provider had a record for it.
class IsbnLookupMetadata extends IsbnLookupResult {
  const IsbnLookupMetadata(this.metadata);
  final BookMetadata metadata;
}

/// A valid ISBN with neither a local match nor any provider metadata.
class IsbnLookupNotFound extends IsbnLookupResult {
  const IsbnLookupNotFound(this.isbn13);
  final String isbn13;
}

/// Resolves a raw ISBN (scanned barcode or typed text) the same way
/// everywhere it can be entered: normalize it, check the local library for
/// an existing book, and otherwise query the metadata providers. Shared by
/// barcode scanning, manual ISBN entry, and shelf search-by-scan so none of
/// them duplicate this logic.
class BookLookupService {
  BookLookupService({BookMetadataService? metadataService})
      : _metadataService = metadataService ?? BookMetadataService();

  final BookMetadataService _metadataService;

  Future<IsbnLookupResult> resolve(
    String rawIsbn,
    LibraryProvider library,
  ) async {
    final isbn13 = IsbnUtils.normalizeToIsbn13(rawIsbn);
    if (isbn13 == null) return const IsbnLookupInvalid();

    final existing = await library.findByIsbn(isbn13);
    if (existing != null) return IsbnLookupExisting(existing);

    BookMetadata? metadata;
    try {
      metadata = await _metadataService.lookup(isbn13);
    } catch (_) {
      metadata = null;
    }

    if (metadata != null) return IsbnLookupMetadata(metadata);
    return IsbnLookupNotFound(isbn13);
  }
}
