enum ReadStatus { unread, reading, read }

extension ReadStatusX on ReadStatus {
  String get storageValue => name;

  String get label {
    switch (this) {
      case ReadStatus.unread:
        return 'Unread';
      case ReadStatus.reading:
        return 'Reading';
      case ReadStatus.read:
        return 'Read';
    }
  }

  static ReadStatus fromStorage(String? value) {
    return ReadStatus.values.firstWhere(
      (s) => s.storageValue == value,
      orElse: () => ReadStatus.unread,
    );
  }
}
