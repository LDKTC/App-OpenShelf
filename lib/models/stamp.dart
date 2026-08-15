/// The reading-status timeline: instead of a single status field, a book
/// carries a history of timestamped stamps. A book's *current* status is
/// derived as the stamp with the latest [ReadingStamp.timestamp] (or "not
/// started" if it has none yet).
enum StampType { reading, finished, dropped, paused }

extension StampTypeX on StampType {
  String get storageValue => name;

  static StampType? fromStorage(String? value) {
    if (value == null) return null;
    for (final type in StampType.values) {
      if (type.storageValue == value) return type;
    }
    return null;
  }
}

/// A single timestamped reading-status entry for a book. Books can have
/// any number of stamps, added/edited/deleted freely, forming a timeline
/// (e.g. started reading, paused, resumed, finished).
class ReadingStamp {
  final int? id;
  final int bookId;
  final StampType type;
  final DateTime timestamp;
  final String? note;

  const ReadingStamp({
    this.id,
    required this.bookId,
    required this.type,
    required this.timestamp,
    this.note,
  });

  ReadingStamp copyWith({
    int? id,
    int? bookId,
    StampType? type,
    DateTime? timestamp,
    String? note,
    bool clearNote = false,
  }) {
    return ReadingStamp(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'bookId': bookId,
      'type': type.storageValue,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory ReadingStamp.fromMap(Map<String, Object?> map) {
    return ReadingStamp(
      id: map['id'] as int?,
      bookId: map['bookId'] as int,
      type: StampTypeX.fromStorage(map['type'] as String?) ?? StampType.reading,
      timestamp: DateTime.parse(map['timestamp'] as String),
      note: map['note'] as String?,
    );
  }
}

/// A book's *current* status is the stamp with the latest [ReadingStamp.timestamp]
/// among its timeline — this is that rule, factored out so it's the same
/// answer everywhere (and unit-testable without a database).
ReadingStamp? latestStamp(Iterable<ReadingStamp> stamps) {
  ReadingStamp? latest;
  for (final stamp in stamps) {
    if (latest == null || stamp.timestamp.isAfter(latest.timestamp)) {
      latest = stamp;
    }
  }
  return latest;
}
