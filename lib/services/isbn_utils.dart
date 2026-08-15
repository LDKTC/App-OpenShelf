/// Helpers for cleaning, validating and classifying ISBNs.
class IsbnUtils {
  IsbnUtils._();

  /// Strips hyphens/spaces and upper-cases a trailing 'x' check digit.
  static String clean(String raw) {
    return raw.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  }

  static bool isValidIsbn10(String isbn) {
    if (isbn.length != 10) return false;
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      final c = isbn[i];
      int digit;
      if (c == 'X' && i == 9) {
        digit = 10;
      } else if (RegExp(r'^\d$').hasMatch(c)) {
        digit = int.parse(c);
      } else {
        return false;
      }
      sum += digit * (10 - i);
    }
    return sum % 11 == 0;
  }

  static bool isValidIsbn13(String isbn) {
    if (isbn.length != 13 || !RegExp(r'^\d{13}$').hasMatch(isbn)) {
      return false;
    }
    var sum = 0;
    for (var i = 0; i < 13; i++) {
      final digit = int.parse(isbn[i]);
      sum += digit * (i.isEven ? 1 : 3);
    }
    return sum % 10 == 0;
  }

  static bool isValidIsbn(String raw) {
    final v = clean(raw);
    return isValidIsbn10(v) || isValidIsbn13(v);
  }

  /// Converts a valid ISBN-10 to its ISBN-13 equivalent (978 prefix).
  static String isbn10ToIsbn13(String isbn10) {
    final core = '978${isbn10.substring(0, 9)}';
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final digit = int.parse(core[i]);
      sum += digit * (i.isEven ? 1 : 3);
    }
    final check = (10 - (sum % 10)) % 10;
    return '$core$check';
  }

  /// Normalizes any valid ISBN-10/13 to its 13-digit form, or null if invalid.
  static String? normalizeToIsbn13(String raw) {
    final v = clean(raw);
    if (isValidIsbn13(v)) return v;
    if (isValidIsbn10(v)) return isbn10ToIsbn13(v);
    return null;
  }
}
