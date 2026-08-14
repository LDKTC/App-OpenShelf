import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/book_metadata.dart';

/// Looks up book metadata from the Google Books public API.
/// No API key is required for basic volume searches.
class GoogleBooksProvider {
  static const _endpoint = 'https://www.googleapis.com/books/v1/volumes';

  Future<BookMetadata?> lookup(String isbn13) async {
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {'q': 'isbn:$isbn13'},
    );

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return null;

    final volumeInfo = items.first['volumeInfo'] as Map<String, dynamic>?;
    if (volumeInfo == null) return null;

    final title = volumeInfo['title'] as String?;
    if (title == null || title.isEmpty) return null;

    final identifiers =
        volumeInfo['industryIdentifiers'] as List<dynamic>? ?? [];
    String? foundIsbn13;
    String? foundIsbn10;
    for (final entry in identifiers) {
      final map = entry as Map<String, dynamic>;
      if (map['type'] == 'ISBN_13') foundIsbn13 = map['identifier'] as String?;
      if (map['type'] == 'ISBN_10') foundIsbn10 = map['identifier'] as String?;
    }

    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final thumbnail = (imageLinks?['thumbnail'] ?? imageLinks?['smallThumbnail'])
        as String?;

    return BookMetadata(
      isbn13: foundIsbn13 ?? isbn13,
      isbn10: foundIsbn10,
      title: title,
      authors: (volumeInfo['authors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      publisher: volumeInfo['publisher'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      description: volumeInfo['description'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      thumbnailUrl: thumbnail?.replaceFirst('http://', 'https://'),
      language: volumeInfo['language'] as String?,
      source: 'google_books',
    );
  }
}
