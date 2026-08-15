/// A photographed page or illustration from inside a book, saved as an
/// in-app reminder (e.g. a favorite spread, a quote, a passage to revisit).
class BookPage {
  final int? id;
  final int bookId;
  final String imagePath;
  final String? pageLabel;
  final String? note;
  final DateTime createdAt;

  const BookPage({
    this.id,
    required this.bookId,
    required this.imagePath,
    this.pageLabel,
    this.note,
    required this.createdAt,
  });

  BookPage copyWith({
    int? id,
    int? bookId,
    String? imagePath,
    String? pageLabel,
    String? note,
    DateTime? createdAt,
    bool clearPageLabel = false,
    bool clearNote = false,
  }) {
    return BookPage(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      imagePath: imagePath ?? this.imagePath,
      pageLabel: clearPageLabel ? null : (pageLabel ?? this.pageLabel),
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'bookId': bookId,
      'imagePath': imagePath,
      'pageLabel': pageLabel,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookPage.fromMap(Map<String, Object?> map) {
    return BookPage(
      id: map['id'] as int?,
      bookId: map['bookId'] as int,
      imagePath: map['imagePath'] as String,
      pageLabel: map['pageLabel'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
