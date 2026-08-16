import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/book_metadata.dart';

/// Looks up light-novel metadata from RanobeDB (https://ranobedb.org),
/// via its public read-only API (https://ranobedb.org/api/v0, documented
/// at https://ranobedb.org/api/docs/v0).
///
/// `GET /releases` matches its `q` parameter against `release.isbn13`
/// exactly whenever `q` looks like an ISBN-13 (starts with "978"/"979"),
/// so a scanned ISBN resolves directly to the matching release instead of
/// a fuzzy title search. From that release, `GET /release/{id}` gives the
/// associated book id, and `GET /book/{id}` gives the full metadata
/// (authors, description, cover) used to build a [BookMetadata]. The
/// book's own release list is still checked against the queried ISBN-13
/// as a final guard — and since each entry in that list carries its own
/// `lang`, the matching entry tells us which language the scanned ISBN
/// was actually published in. A book can have multiple language editions
/// (e.g. the original Japanese plus an English translation) sharing one
/// `book` record but with distinct entries in its `titles` array, so that
/// language is then used to pick the title in the matching language
/// (falling back to the book's default title when there's no dedicated
/// entry for it) rather than always the original-language title. Since
/// most scanned books aren't light novels, this rarely matches — that's
/// expected, and callers already treat a null result as "try the next
/// provider".
class RanobeDbProvider {
  RanobeDbProvider({http.Client? client}) : _client = client ?? http.Client();

  static const _endpoint = 'https://ranobedb.org/api/v0';
  static const _imageBase = 'https://images.ranobedb.org';

  final http.Client _client;

  Future<BookMetadata?> lookup(String isbn13) async {
    final releaseId = await _findReleaseId(isbn13);
    if (releaseId == null) return null;

    final bookId = await _findBookId(releaseId);
    if (bookId == null) return null;

    final detailUri = Uri.parse('$_endpoint/book/$bookId');
    final detailResponse = await _client
        .get(detailUri)
        .timeout(const Duration(seconds: 10));
    if (detailResponse.statusCode != 200) return null;

    final book = (jsonDecode(detailResponse.body)
        as Map<String, dynamic>)['book'] as Map<String, dynamic>?;
    if (book == null) return null;

    final releases = book['releases'] as List<dynamic>? ?? [];
    String? matchedLang;
    var isMatch = false;
    for (final r in releases) {
      final map = r as Map<String, dynamic>;
      if (map['isbn13'] == isbn13) {
        isMatch = true;
        matchedLang = map['lang'] as String?;
        break;
      }
    }
    if (!isMatch) return null;

    return _toMetadata(book, isbn13, matchedLang);
  }

  Future<int?> _findReleaseId(String isbn13) async {
    final searchUri = Uri.parse('$_endpoint/releases').replace(
      queryParameters: {'q': isbn13, 'limit': '5'},
    );
    final searchResponse = await _client
        .get(searchUri)
        .timeout(const Duration(seconds: 10));
    if (searchResponse.statusCode != 200) return null;

    final searchBody =
        jsonDecode(searchResponse.body) as Map<String, dynamic>;
    final releases = searchBody['releases'] as List<dynamic>? ?? [];

    for (final release in releases) {
      final map = release as Map<String, dynamic>;
      if (map['isbn13'] == isbn13) return map['id'] as int?;
    }
    return null;
  }

  Future<int?> _findBookId(int releaseId) async {
    final releaseUri = Uri.parse('$_endpoint/release/$releaseId');
    final releaseResponse = await _client
        .get(releaseUri)
        .timeout(const Duration(seconds: 10));
    if (releaseResponse.statusCode != 200) return null;

    final release = (jsonDecode(releaseResponse.body)
        as Map<String, dynamic>)['release'] as Map<String, dynamic>?;
    final books = release?['books'] as List<dynamic>? ?? [];
    if (books.isEmpty) return null;

    return (books.first as Map<String, dynamic>)['id'] as int?;
  }

  BookMetadata? _toMetadata(
    Map<String, dynamic> book,
    String isbn13,
    String? lang,
  ) {
    final title = _titleFor(book, lang) ??
        (book['title'] as String?) ??
        (book['romaji'] as String?);
    if (title == null || title.isEmpty) return null;

    final publishers = (book['publishers'] as List<dynamic>? ?? [])
        .map((p) => (p as Map<String, dynamic>)['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    final authors = <String>{};
    final illustrators = <String>{};
    for (final edition in (book['editions'] as List<dynamic>? ?? [])) {
      final staff =
          (edition as Map<String, dynamic>)['staff'] as List<dynamic>? ?? [];
      for (final entry in staff) {
        final map = entry as Map<String, dynamic>;
        final name = (map['name'] as String?) ?? (map['romaji'] as String?);
        if (name == null || name.isEmpty) continue;
        switch (map['role_type']) {
          case 'author':
            authors.add(name);
          case 'illustrator':
            illustrators.add(name);
        }
      }
    }

    final filename = (book['image'] as Map<String, dynamic>?)?['filename']
        as String?;

    return BookMetadata(
      isbn13: isbn13,
      title: title,
      authors: authors.toList(),
      illustrators: illustrators.toList(),
      publisher: publishers.isEmpty ? null : publishers.join(', '),
      publishedDate: book['c_release_date']?.toString(),
      description: (book['description'] as String?)?.trim(),
      thumbnailUrl: filename == null ? null : '$_imageBase/$filename',
      language: lang,
      source: 'ranobedb',
    );
  }

  /// The title of [book] in [lang], from its `titles` array of per-language
  /// `{lang, title, romaji}` entries — null when [lang] is unknown or the
  /// book has no dedicated entry for it, so callers fall back to the
  /// book's default title.
  String? _titleFor(Map<String, dynamic> book, String? lang) {
    if (lang == null) return null;
    final titles = book['titles'] as List<dynamic>? ?? [];
    for (final entry in titles) {
      final map = entry as Map<String, dynamic>;
      if (map['lang'] == lang) {
        return (map['title'] as String?) ?? (map['romaji'] as String?);
      }
    }
    return null;
  }
}
