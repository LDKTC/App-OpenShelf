import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/stamp.dart';
import '../state/library_provider.dart';
import 'status_chip.dart';

/// The full add/edit/delete reading-status timeline for a single book:
/// every [ReadingStamp] it has, most recent first, plus a button to add a
/// new one. Stamps can be edited or deleted at any time.
class StampTimeline extends StatelessWidget {
  const StampTimeline({super.key, required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final stamps = library.stampsFor(bookId);
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t.readingTimelineTitle, style: Theme.of(context).textTheme.labelLarge),
            TextButton.icon(
              onPressed: () => showStampEditorDialog(context, bookId: bookId),
              icon: const Icon(Icons.add, size: 18),
              label: Text(t.addStamp),
            ),
          ],
        ),
        if (stamps.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              t.noStampsYet,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          for (final stamp in stamps) _StampTile(stamp: stamp),
      ],
    );
  }
}

class _StampTile extends StatelessWidget {
  const _StampTile({required this.stamp});

  final ReadingStamp stamp;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) =
        stampVisuals(AppLocalizations.of(context), stamp.type);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label),
      subtitle: Text(
        [formatStampTimestamp(stamp.timestamp), if (stamp.note != null) stamp.note!]
            .join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showStampEditorDialog(
              context,
              bookId: stamp.bookId,
              existing: stamp,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _confirmDelete(context, stamp),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ReadingStamp stamp) async {
    final library = context.read<LibraryProvider>();
    final t = AppLocalizations.of(context);
    final (_, _, statusLabel) = stampVisuals(t, stamp.type);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteStampTitle),
        content: Text(t.removeStampConfirm(statusLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && stamp.id != null) {
      await library.deleteStamp(stamp.id!);
    }
  }
}

/// Opens the add/edit dialog for a stamp. Pass [existing] to edit it in
/// place; omit it to add a new stamp to [bookId]'s timeline.
Future<void> showStampEditorDialog(
  BuildContext context, {
  required int bookId,
  ReadingStamp? existing,
}) {
  return showDialog(
    context: context,
    builder: (_) => _StampEditorDialog(bookId: bookId, existing: existing),
  );
}

class _StampEditorDialog extends StatefulWidget {
  const _StampEditorDialog({required this.bookId, this.existing});

  final int bookId;
  final ReadingStamp? existing;

  @override
  State<_StampEditorDialog> createState() => _StampEditorDialogState();
}

class _StampEditorDialogState extends State<_StampEditorDialog> {
  late StampType _type;
  late DateTime _timestamp;
  late final TextEditingController _note;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type ?? StampType.reading;
    _timestamp = widget.existing?.timestamp ?? DateTime.now();
    _note = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null || !mounted) return;
    setState(() {
      _timestamp = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final library = context.read<LibraryProvider>();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    if (_isEditing) {
      await library.updateStamp(
        widget.existing!.copyWith(
          type: _type,
          timestamp: _timestamp,
          note: note,
          clearNote: note == null,
        ),
      );
    } else {
      await library.addStamp(widget.bookId, _type, timestamp: _timestamp, note: note);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_isEditing ? t.editStamp : t.addStamp),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in StampType.values)
                  ChoiceChip(
                    label: Text(stampVisuals(t, type).$3),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateTime,
              child: InputDecorator(
                decoration: InputDecoration(labelText: t.whenField),
                child: Text(formatStampTimestamp(_timestamp)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: t.noteField),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(t.save)),
      ],
    );
  }
}

String formatStampTimestamp(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}
