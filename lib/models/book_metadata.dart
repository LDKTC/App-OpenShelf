/// A metadata lookup result, before it becomes a saved [Book].
class BookMetadata {
  final String? isbn13;
  final String? isbn10;
  final String title;
  final List<String> authors;
  final String? publisher;
  final String? publishedDate;
  final String? description;
  final int? pageCount;
  final String? thumbnailUrl;
  final String? language;

  /// Which provider resolved this record, e.g. 'google_books',
  /// 'open_library', 'nlt_alma_sru'.
  final String source;

  const BookMetadata({
    this.isbn13,
    this.isbn10,
    required this.title,
    this.authors = const [],
    this.publisher,
    this.publishedDate,
    this.description,
    this.pageCount,
    this.thumbnailUrl,
    this.language,
    required this.source,
  });
}
