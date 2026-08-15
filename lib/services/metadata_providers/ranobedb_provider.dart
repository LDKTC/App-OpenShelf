import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/book_metadata.dart';

/// Looks up light-novel metadata from RanobeDB (https://ranobedb.org),
/// via its public read-only API (https://ranobedb.org/api/v0, documented
/// at https://ranobedb.org/api/docs/v0).
///
/// RanobeDB's API has no dedicated ISBN search — `GET /books` only takes
/// a free-text `q` parameter (title/alias search). This sends the ISBN as
/// that query text, then only accepts a candidate whose release list
/// (fetched via `GET /book/{id}`) actually contains the queried ISBN-13,
/// so a fuzzy/irrelevant title match never gets returned as a hit. Since
/// most scanned books aren't light novels, this rarely matches — that's
/// expected, and callers already treat a null result as "try the next
/// provider".
class RanobeDbProvider {
  RanobeDbProvider({http.Client? client}) : _client = client ?? http.Client();

  static const _endpoint = 'https://ranobedb.org/api/v0';
  static const _imageBase = 'https://images.ranobedb.org';

  final http.Client _client;

  Future<BookMetadata?> lookup(String isbn13) async {
    final searchUri = Uri.parse('$_endpoint/books').replace(
      queryParameters: {'q': isbn13, 'limit': '5'},
    );
    final searchResponse = await _client
        .get(searchUri)
        .timeout(const Duration(seconds: 10));
    if (searchResponse.statusCode != 200) return null;

    final searchBody =
        jsonDecode(searchResponse.body) as Map<String, dynamic>;
    final candidates = searchBody['books'] as List<dynamic>? ?? [];

    for (final candidate in candidates) {
      final id = (candidate as Map<String, dynamic>)['id'];
      if (id == null) continue;

      final detailUri = Uri.parse('$_endpoint/book/$id');
      final detailResponse = await _client
          .get(detailUri)
          .timeout(const Duration(seconds: 10));
      if (detailResponse.statusCode != 200) continue;

      final book = (jsonDecode(detailResponse.body)
          as Map<String, dynamic>)['book'] as Map<String, dynamic>?;
      if (book == null) continue;

      final releases = book['releases'] as List<dynamic>? ?? [];
      final isMatch = releases.any(
        (r) => (r as Map<String, dynamic>)['isbn13'] == isbn13,
      );
      if (!isMatch) continue;

      final metadata = _toMetadata(book, isbn13);
      if (metadata != null) return metadata;
    }
    return null;
  }

  BookMetadata? _toMetadata(Map<String, dynamic> book, String isbn13) {
    final title = (book['title'] as String?) ?? (book['romaji'] as String?);
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
      source: 'ranobedb',
    );
  }
}
