import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../services/settings_service.dart';

/// The section header a book falls under for the current [sortField], or
/// null when that field isn't grouped (title/author/publisher/ISBN stay a
/// plain flat list/shelf, same as before sorting existed).
String? groupHeaderFor(Book book, LibrarySortField sortField, AppLocalizations t) {
  switch (sortField) {
    case LibrarySortField.dateAdded:
      final d = book.dateAdded;
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return '${d.year}-$mm-$dd';
    case LibrarySortField.series:
      final series = book.series;
      return (series == null || series.isEmpty) ? t.noSeriesGroupLabel : series;
    case LibrarySortField.languageGenre:
      final parts = [
        if (book.language != null && book.language!.isNotEmpty) book.language!,
        if (book.genre != null && book.genre!.isNotEmpty) book.genre!,
      ];
      return parts.isEmpty ? t.noLanguageGenreGroupLabel : parts.join(' · ');
    case LibrarySortField.title:
    case LibrarySortField.author:
    case LibrarySortField.publisher:
    case LibrarySortField.isbn:
      return null;
  }
}

/// A contiguous run of already-sorted [books] sharing the same
/// [groupHeaderFor] label. [label] is null only for the single section
/// covering the whole list when [sortField] isn't a grouped field.
class BookSection {
  BookSection(this.label, this.books);

  final String? label;
  final List<Book> books;
}

/// Splits the already-sorted [books] into [BookSection]s by [groupHeaderFor].
/// When [sortField] doesn't group (title/author/publisher/ISBN), returns a
/// single section with a null label holding every book, so callers can treat
/// "not grouped" as "one section" rather than a special case.
List<BookSection> buildBookSections(
  List<Book> books,
  LibrarySortField sortField,
  AppLocalizations t,
) {
  if (books.isEmpty) return const [];
  if (groupHeaderFor(books.first, sortField, t) == null) {
    return [BookSection(null, books)];
  }

  final sections = <BookSection>[];
  String? currentLabel;
  var currentBooks = <Book>[];
  for (final book in books) {
    final header = groupHeaderFor(book, sortField, t)!;
    if (header != currentLabel) {
      if (currentBooks.isNotEmpty) {
        sections.add(BookSection(currentLabel, currentBooks));
      }
      currentLabel = header;
      currentBooks = [];
    }
    currentBooks.add(book);
  }
  if (currentBooks.isNotEmpty) {
    sections.add(BookSection(currentLabel, currentBooks));
  }
  return sections;
}
