import 'package:flutter_test/flutter_test.dart';
import 'package:openshelf/models/stamp.dart';

void main() {
  group('latestStamp', () {
    test('returns null for an empty list', () {
      expect(latestStamp(const []), isNull);
    });

    test('a single stamp is its own latest', () {
      final only = ReadingStamp(
        bookId: 2,
        type: StampType.dropped,
        timestamp: DateTime(2023, 5, 5),
      );
      expect(latestStamp([only]), same(only));
    });

    test('returns the stamp with the latest timestamp regardless of input order', () {
      final oldest = ReadingStamp(
        bookId: 1,
        type: StampType.reading,
        timestamp: DateTime(2024, 1, 1),
      );
      final middle = ReadingStamp(
        bookId: 1,
        type: StampType.paused,
        timestamp: DateTime(2024, 6, 1),
      );
      final newest = ReadingStamp(
        bookId: 1,
        type: StampType.finished,
        timestamp: DateTime(2024, 12, 1),
      );

      expect(latestStamp([middle, oldest, newest]), same(newest));
      expect(latestStamp([newest, oldest, middle]), same(newest));
      expect(latestStamp([oldest, middle, newest]), same(newest));
    });
  });

  group('StampTypeX.fromStorage', () {
    test('round-trips every stamp type through its storage value', () {
      for (final type in StampType.values) {
        expect(StampTypeX.fromStorage(type.storageValue), type);
      }
    });

    test('returns null for unrecognized or missing values', () {
      expect(StampTypeX.fromStorage('not_a_type'), isNull);
      expect(StampTypeX.fromStorage(null), isNull);
    });
  });
}
