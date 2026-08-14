import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/book_metadata.dart';

/// Looks up book metadata from the Open Library Books API.
/// Used as a fallback when Google Books has no record.
class OpenLibraryProvider {
  static const _endpoint = 'https://openlibrary.org/api/books';

  Future<BookMetadata?> lookup(String isbn13) async {
    final bibkey = 'ISBN:$isbn13';
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'bibkeys': bibkey,
      'format': 'json',
      'jscmd': 'data',
    });

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final record = body[bibkey] as Map<String, dynamic>?;
    if (record == null) return null;

    final title = record['title'] as String?;
    if (title == null || title.isEmpty) return null;

    final authors = (record['authors'] as List<dynamic>? ?? [])
        .map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    final publishers = (record['publishers'] as List<dynamic>? ?? [])
        .map((p) => (p as Map<String, dynamic>)['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    final cover = record['cover'] as Map<String, dynamic>?;
    final thumbnail = (cover?['medium'] ?? cover?['small']) as String?;

    int? pageCount;
    final pages = record['number_of_pages'];
    if (pages is int) pageCount = pages;

    return BookMetadata(
      isbn13: isbn13,
      title: title,
      authors: authors,
      publisher: publishers.isEmpty ? null : publishers.join(', '),
      publishedDate: record['publish_date'] as String?,
      description: _extractDescription(record['notes']) ??
          _extractDescription(record['excerpts']),
      pageCount: pageCount,
      thumbnailUrl: thumbnail,
      source: 'open_library',
    );
  }

  String? _extractDescription(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) {
        return first['text'] as String?;
      }
    }
    return null;
  }
}
