import 'package:flutter_test/flutter_test.dart';
import 'package:openshelf/services/isbn_utils.dart';

void main() {
  group('IsbnUtils', () {
    test('validates a known ISBN-13', () {
      expect(IsbnUtils.isValidIsbn13('9780306406157'), isTrue);
      expect(IsbnUtils.isValidIsbn13('9780306406158'), isFalse);
    });

    test('validates a known ISBN-10', () {
      expect(IsbnUtils.isValidIsbn10('0306406152'), isTrue);
      expect(IsbnUtils.isValidIsbn10('0306406153'), isFalse);
    });

    test('converts ISBN-10 to ISBN-13', () {
      expect(IsbnUtils.isbn10ToIsbn13('0306406152'), '9780306406157');
    });

    test('normalizes hyphenated ISBNs', () {
      expect(
        IsbnUtils.normalizeToIsbn13('978-0-306-40615-7'),
        '9780306406157',
      );
      expect(IsbnUtils.normalizeToIsbn13('0-306-40615-2'), '9780306406157');
    });

    test('rejects invalid input', () {
      expect(IsbnUtils.normalizeToIsbn13('not an isbn'), isNull);
    });

    test('recognizes Thai ISBN group identifiers', () {
      expect(IsbnUtils.isThaiIsbn('9786160000000'), isTrue);
      expect(IsbnUtils.isThaiIsbn('9789740000000'), isTrue);
      expect(IsbnUtils.isThaiIsbn('9780306406157'), isFalse);
    });
  });
}
