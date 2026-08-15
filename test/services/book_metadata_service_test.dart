import 'package:flutter_test/flutter_test.dart';
import 'package:quetzalib/models/book_metadata.dart';
import 'package:quetzalib/services/book_metadata_service.dart';
import 'package:quetzalib/services/metadata_providers/google_books_provider.dart';
import 'package:quetzalib/services/metadata_providers/nlt_alma_sru_provider.dart';
import 'package:quetzalib/services/metadata_providers/open_library_provider.dart';
import 'package:quetzalib/services/metadata_providers/ranobedb_provider.dart';

const _thaiIsbn13 = '9786160000005';
const _nonThaiIsbn13 = '9780306406157';

BookMetadata _metadataFrom(String source) =>
    BookMetadata(title: 'Title from $source', source: source);

class _FakeGoogleBooks implements GoogleBooksProvider {
  _FakeGoogleBooks(this._calls, {this.result, this.error});
  final List<String> _calls;
  final BookMetadata? result;
  final Object? error;

  @override
  Future<BookMetadata?> lookup(String isbn13) async {
    _calls.add('google_books');
    if (error != null) throw error!;
    return result;
  }
}

class _FakeOpenLibrary implements OpenLibraryProvider {
  _FakeOpenLibrary(this._calls, {this.result, this.error});
  final List<String> _calls;
  final BookMetadata? result;
  final Object? error;

  @override
  Future<BookMetadata?> lookup(String isbn13) async {
    _calls.add('open_library');
    if (error != null) throw error!;
    return result;
  }
}

class _FakeNltAlmaSru implements NltAlmaSruProvider {
  _FakeNltAlmaSru(this._calls, {this.result, this.error});
  final List<String> _calls;
  final BookMetadata? result;
  final Object? error;

  @override
  Future<BookMetadata?> lookup(String isbn13) async {
    _calls.add('nlt_alma_sru');
    if (error != null) throw error!;
    return result;
  }
}

class _FakeRanobeDb implements RanobeDbProvider {
  _FakeRanobeDb(this._calls, {this.result, this.error});
  final List<String> _calls;
  final BookMetadata? result;
  final Object? error;

  @override
  Future<BookMetadata?> lookup(String isbn13) async {
    _calls.add('ranobedb');
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  group('BookMetadataService', () {
    test('returns null immediately for an invalid ISBN', () async {
      final calls = <String>[];
      final service = BookMetadataService(
        googleBooks: _FakeGoogleBooks(calls),
        openLibrary: _FakeOpenLibrary(calls),
        nltAlmaSru: _FakeNltAlmaSru(calls),
        ranobeDb: _FakeRanobeDb(calls),
      );

      final result = await service.lookup('not an isbn');

      expect(result, isNull);
      expect(calls, isEmpty);
    });

    test(
        'tries NLT Alma SRU first for a Thai ISBN, falling through to '
        'RanobeDB last when nothing else matches', () async {
      final calls = <String>[];
      final service = BookMetadataService(
        googleBooks: _FakeGoogleBooks(calls),
        openLibrary: _FakeOpenLibrary(calls),
        nltAlmaSru: _FakeNltAlmaSru(calls),
        ranobeDb: _FakeRanobeDb(calls, result: _metadataFrom('ranobedb')),
      );

      final result = await service.lookup(_thaiIsbn13);

      expect(result?.source, 'ranobedb');
      expect(
        calls,
        ['nlt_alma_sru', 'google_books', 'open_library', 'ranobedb'],
      );
    });

    test('tries Google Books first for a non-Thai ISBN, RanobeDB last',
        () async {
      final calls = <String>[];
      final service = BookMetadataService(
        googleBooks: _FakeGoogleBooks(calls),
        openLibrary: _FakeOpenLibrary(calls),
        nltAlmaSru: _FakeNltAlmaSru(calls),
        ranobeDb: _FakeRanobeDb(calls, result: _metadataFrom('ranobedb')),
      );

      final result = await service.lookup(_nonThaiIsbn13);

      expect(result?.source, 'ranobedb');
      expect(
        calls,
        ['google_books', 'open_library', 'nlt_alma_sru', 'ranobedb'],
      );
    });

    test('stops at the first provider that finds a match', () async {
      final calls = <String>[];
      final service = BookMetadataService(
        googleBooks:
            _FakeGoogleBooks(calls, result: _metadataFrom('google_books')),
        openLibrary: _FakeOpenLibrary(calls),
        nltAlmaSru: _FakeNltAlmaSru(calls),
        ranobeDb: _FakeRanobeDb(calls),
      );

      final result = await service.lookup(_nonThaiIsbn13);

      expect(result?.source, 'google_books');
      expect(calls, ['google_books']);
    });

    test('skips a provider that throws and keeps trying the rest',
        () async {
      final calls = <String>[];
      final service = BookMetadataService(
        googleBooks: _FakeGoogleBooks(calls, error: Exception('boom')),
        openLibrary: _FakeOpenLibrary(calls),
        nltAlmaSru: _FakeNltAlmaSru(calls),
        ranobeDb: _FakeRanobeDb(calls, result: _metadataFrom('ranobedb')),
      );

      final result = await service.lookup(_nonThaiIsbn13);

      expect(result?.source, 'ranobedb');
      expect(
        calls,
        ['google_books', 'open_library', 'nlt_alma_sru', 'ranobedb'],
      );
    });

    test('returns null when every provider misses', () async {
      final calls = <String>[];
      final service = BookMetadataService(
        googleBooks: _FakeGoogleBooks(calls),
        openLibrary: _FakeOpenLibrary(calls),
        nltAlmaSru: _FakeNltAlmaSru(calls),
        ranobeDb: _FakeRanobeDb(calls),
      );

      final result = await service.lookup(_thaiIsbn13);

      expect(result, isNull);
      expect(
        calls,
        ['nlt_alma_sru', 'google_books', 'open_library', 'ranobedb'],
      );
    });
  });
}
