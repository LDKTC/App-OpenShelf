import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quetzalib/services/metadata_providers/ranobedb_provider.dart';

http.Response _json(Object body, {int statusCode = 200}) =>
    http.Response(jsonEncode(body), statusCode);

void main() {
  group('RanobeDbProvider', () {
    const isbn13 = '9781638586301';

    test('returns metadata when the release search matches the ISBN',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/releases') {
          expect(request.url.queryParameters['q'], isbn13);
          return _json({
            'releases': [
              {'id': 7, 'isbn13': isbn13},
            ],
          });
        }
        if (request.url.path == '/api/v0/release/7') {
          return _json({
            'release': {
              'books': [
                {'id': 42},
              ],
            },
          });
        }
        if (request.url.path == '/api/v0/book/42') {
          return _json({
            'book': {
              'title': 'Test Light Novel',
              'releases': [
                {'isbn13': isbn13},
              ],
              'publishers': [
                {'name': 'Yen Press'},
              ],
              'editions': [
                {
                  'staff': [
                    {'role_type': 'author', 'name': 'Jane Author'},
                    {'role_type': 'illustrator', 'name': 'Some Illustrator'},
                  ],
                },
              ],
              'c_release_date': '2024-01-01',
              'description': ' A story. ',
              'image': {'filename': 'cover.jpg'},
            },
          });
        }
        return http.Response('not found', 404);
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNotNull);
      expect(result!.title, 'Test Light Novel');
      expect(result.authors, ['Jane Author']);
      expect(result.illustrators, ['Some Illustrator']);
      expect(result.publisher, 'Yen Press');
      expect(result.publishedDate, '2024-01-01');
      expect(result.description, 'A story.');
      expect(result.thumbnailUrl, 'https://images.ranobedb.org/cover.jpg');
      expect(result.isbn13, isbn13);
      expect(result.source, 'ranobedb');
    });

    test('ignores a release result whose ISBN does not match', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/releases') {
          return _json({
            'releases': [
              {'id': 7, 'isbn13': '9780000000000'},
            ],
          });
        }
        return http.Response('not found', 404);
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNull);
    });

    test('returns null when the book detail lacks the queried ISBN',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/releases') {
          return _json({
            'releases': [
              {'id': 7, 'isbn13': isbn13},
            ],
          });
        }
        if (request.url.path == '/api/v0/release/7') {
          return _json({
            'release': {
              'books': [
                {'id': 42},
              ],
            },
          });
        }
        return _json({
          'book': {
            'title': 'Unrelated Book',
            'releases': [
              {'isbn13': '9780000000000'},
            ],
          },
        });
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNull);
    });

    test('returns null when the release search has no matches', () async {
      final client = MockClient((request) async {
        return _json({'releases': []});
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNull);
    });

    test('returns null when the release search request fails', () async {
      final client = MockClient((request) async {
        return http.Response('server error', 500);
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNull);
    });

    test('returns null when the release detail request fails', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/releases') {
          return _json({
            'releases': [
              {'id': 7, 'isbn13': isbn13},
            ],
          });
        }
        return http.Response('server error', 500);
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNull);
    });

    test('returns null when the release has no associated book', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/releases') {
          return _json({
            'releases': [
              {'id': 7, 'isbn13': isbn13},
            ],
          });
        }
        if (request.url.path == '/api/v0/release/7') {
          return _json({
            'release': {'books': []},
          });
        }
        return http.Response('not found', 404);
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNull);
    });

    test('returns null when the book detail request fails', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/releases') {
          return _json({
            'releases': [
              {'id': 7, 'isbn13': isbn13},
            ],
          });
        }
        if (request.url.path == '/api/v0/release/7') {
          return _json({
            'release': {
              'books': [
                {'id': 42},
              ],
            },
          });
        }
        return http.Response('server error', 500);
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNull);
    });
  });
}
