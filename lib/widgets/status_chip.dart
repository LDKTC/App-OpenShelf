import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/stamp.dart';

/// The color/icon/label used to represent a stamp type wherever it shows
/// up in the UI (the current-status chip, the timeline, the add/edit
/// dialog). `null` means "not started" (no stamps yet).
(Color, IconData, String) stampVisuals(AppLocalizations t, StampType? type) {
  return switch (type) {
    null => (Colors.grey, Icons.menu_book_outlined, t.statusNotStarted),
    StampType.reading => (Colors.orange, Icons.auto_stories, t.statusReading),
    StampType.finished => (Colors.green, Icons.check_circle, t.statusFinished),
    StampType.dropped => (Colors.red, Icons.block, t.statusDropped),
    StampType.paused => (Colors.blue, Icons.pause_circle_outline, t.statusPaused),
  };
}

/// Shows a book's *current* reading status: the type of its most recent
/// [ReadingStamp], or "Not started" when [currentType] is null (no stamps
/// yet).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.currentType});

  final StampType? currentType;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) =
        stampVisuals(AppLocalizations.of(context), currentType);
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
