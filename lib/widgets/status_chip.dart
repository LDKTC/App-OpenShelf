import 'package:flutter/material.dart';

import '../models/read_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReadStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      ReadStatus.unread => (Colors.grey, Icons.menu_book_outlined),
      ReadStatus.reading => (Colors.orange, Icons.auto_stories),
      ReadStatus.read => (Colors.green, Icons.check_circle),
    };
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(status.label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
