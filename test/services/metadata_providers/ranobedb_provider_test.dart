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

    test('returns metadata when a candidate release matches the ISBN',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/books') {
          expect(request.url.queryParameters['q'], isbn13);
          return _json({
            'books': [
              {'id': 42},
            ],
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

    test('skips candidates whose releases do not contain the ISBN',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/books') {
          return _json({
            'books': [
              {'id': 1},
              {'id': 2},
            ],
          });
        }
        if (request.url.path == '/api/v0/book/1') {
          return _json({
            'book': {
              'title': 'Wrong Match',
              'releases': [
                {'isbn13': '9780000000000'},
              ],
            },
          });
        }
        if (request.url.path == '/api/v0/book/2') {
          return _json({
            'book': {
              'title': 'Right Match',
              'releases': [
                {'isbn13': isbn13},
              ],
            },
          });
        }
        return http.Response('not found', 404);
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNotNull);
      expect(result!.title, 'Right Match');
    });

    test('returns null when no candidate matches the ISBN', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/books') {
          return _json({
            'books': [
              {'id': 1},
            ],
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

    test('returns null when the search response has no candidates',
        () async {
      final client = MockClient((request) async {
        return _json({'books': []});
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNull);
    });

    test('returns null when the search request fails', () async {
      final client = MockClient((request) async {
        return http.Response('server error', 500);
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNull);
    });

    test('skips a candidate whose detail request fails and tries the next',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v0/books') {
          return _json({
            'books': [
              {'id': 1},
              {'id': 2},
            ],
          });
        }
        if (request.url.path == '/api/v0/book/1') {
          return http.Response('server error', 500);
        }
        return _json({
          'book': {
            'title': 'Recovered Match',
            'releases': [
              {'isbn13': isbn13},
            ],
          },
        });
      });

      final result = await RanobeDbProvider(client: client).lookup(isbn13);

      expect(result, isNotNull);
      expect(result!.title, 'Recovered Match');
    });
  });
}
