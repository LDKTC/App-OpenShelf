import 'read_status.dart';

class Book {
  final int? id;
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
  final ReadStatus status;
  final int? rating;
  final String? notes;
  final String? source;
  final DateTime dateAdded;
  final DateTime? dateStarted;
  final DateTime? dateFinished;

  const Book({
    this.id,
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
    this.status = ReadStatus.unread,
    this.rating,
    this.notes,
    this.source,
    required this.dateAdded,
    this.dateStarted,
    this.dateFinished,
  });

  String get authorsDisplay =>
      authors.isEmpty ? 'Unknown author' : authors.join(', ');

  Book copyWith({
    int? id,
    String? isbn13,
    String? isbn10,
    String? title,
    List<String>? authors,
    String? publisher,
    String? publishedDate,
    String? description,
    int? pageCount,
    String? thumbnailUrl,
    String? language,
    ReadStatus? status,
    int? rating,
    String? notes,
    String? source,
    DateTime? dateAdded,
    DateTime? dateStarted,
    DateTime? dateFinished,
    bool clearDateStarted = false,
    bool clearDateFinished = false,
  }) {
    return Book(
      id: id ?? this.id,
      isbn13: isbn13 ?? this.isbn13,
      isbn10: isbn10 ?? this.isbn10,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      description: description ?? this.description,
      pageCount: pageCount ?? this.pageCount,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      language: language ?? this.language,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      dateAdded: dateAdded ?? this.dateAdded,
      dateStarted:
          clearDateStarted ? null : (dateStarted ?? this.dateStarted),
      dateFinished:
          clearDateFinished ? null : (dateFinished ?? this.dateFinished),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'isbn13': isbn13,
      'isbn10': isbn10,
      'title': title,
      'authors': authors.join('|'),
      'publisher': publisher,
      'publishedDate': publishedDate,
      'description': description,
      'pageCount': pageCount,
      'thumbnailUrl': thumbnailUrl,
      'language': language,
      'status': status.storageValue,
      'rating': rating,
      'notes': notes,
      'source': source,
      'dateAdded': dateAdded.toIso8601String(),
      'dateStarted': dateStarted?.toIso8601String(),
      'dateFinished': dateFinished?.toIso8601String(),
    };
  }

  factory Book.fromMap(Map<String, Object?> map) {
    final authorsRaw = map['authors'] as String?;
    return Book(
      id: map['id'] as int?,
      isbn13: map['isbn13'] as String?,
      isbn10: map['isbn10'] as String?,
      title: map['title'] as String,
      authors: (authorsRaw == null || authorsRaw.isEmpty)
          ? const []
          : authorsRaw.split('|'),
      publisher: map['publisher'] as String?,
      publishedDate: map['publishedDate'] as String?,
      description: map['description'] as String?,
      pageCount: map['pageCount'] as int?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      language: map['language'] as String?,
      status: ReadStatusX.fromStorage(map['status'] as String?),
      rating: map['rating'] as int?,
      notes: map['notes'] as String?,
      source: map['source'] as String?,
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      dateStarted: map['dateStarted'] == null
          ? null
          : DateTime.parse(map['dateStarted'] as String),
      dateFinished: map['dateFinished'] == null
          ? null
          : DateTime.parse(map['dateFinished'] as String),
    );
  }
}
