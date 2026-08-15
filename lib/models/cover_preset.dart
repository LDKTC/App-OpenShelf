/// A saved front-cover/spine/back-cover photo set for a book. A book can
/// have several presets (e.g. different editions); exactly one of them is
/// [isActive] at a time, and that's the one used to render the book on the
/// visual shelf.
class BookCoverPreset {
  final int? id;
  final int bookId;
  final String? label;

  /// Local file path, or an `http(s)://` URL when this slot was promoted
  /// straight from the book's API thumbnail instead of being scanned.
  final String? frontImagePath;
  final String? spineImagePath;
  final String? backImagePath;
  final bool isActive;
  final DateTime createdAt;

  const BookCoverPreset({
    this.id,
    required this.bookId,
    this.label,
    this.frontImagePath,
    this.spineImagePath,
    this.backImagePath,
    this.isActive = false,
    required this.createdAt,
  });

  bool get isEmpty =>
      frontImagePath == null && spineImagePath == null && backImagePath == null;

  BookCoverPreset copyWith({
    int? id,
    int? bookId,
    String? label,
    String? frontImagePath,
    String? spineImagePath,
    String? backImagePath,
    bool? isActive,
    DateTime? createdAt,
    bool clearLabel = false,
    bool clearFrontImagePath = false,
    bool clearSpineImagePath = false,
    bool clearBackImagePath = false,
  }) {
    return BookCoverPreset(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      label: clearLabel ? null : (label ?? this.label),
      frontImagePath: clearFrontImagePath
          ? null
          : (frontImagePath ?? this.frontImagePath),
      spineImagePath: clearSpineImagePath
          ? null
          : (spineImagePath ?? this.spineImagePath),
      backImagePath:
          clearBackImagePath ? null : (backImagePath ?? this.backImagePath),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'bookId': bookId,
      'label': label,
      'frontImagePath': frontImagePath,
      'spineImagePath': spineImagePath,
      'backImagePath': backImagePath,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookCoverPreset.fromMap(Map<String, Object?> map) {
    return BookCoverPreset(
      id: map['id'] as int?,
      bookId: map['bookId'] as int,
      label: map['label'] as String?,
      frontImagePath: map['frontImagePath'] as String?,
      spineImagePath: map['spineImagePath'] as String?,
      backImagePath: map['backImagePath'] as String?,
      isActive: (map['isActive'] as int? ?? 0) != 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
