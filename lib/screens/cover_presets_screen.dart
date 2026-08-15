import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/cover_preset.dart';
import '../services/image_storage_service.dart';
import '../state/library_provider.dart';
import 'cover_scan_screen.dart';

/// Manage a book's saved cover/spine/back-cover presets: pick which one
/// renders on the visual shelf, rename or delete any of them, or scan a
/// new one.
class CoverPresetsScreen extends StatelessWidget {
  const CoverPresetsScreen({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final presets = library.coverPresetsFor(book.id!);

    return Scaffold(
      appBar: AppBar(title: const Text('Book covers')),
      body: presets.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _PresetCard(preset: presets[index], book: book),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CoverScanScreen(book: book)),
        ),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Scan new preset'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_back_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No scanned covers yet. Scan the front cover and spine to '
              'show this book as artwork on your shelf.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.preset, required this.book});

  final BookCoverPreset preset;
  final Book book;

  void _editPhotos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoverScanScreen(book: book, existingPreset: preset),
      ),
    );
  }

  Future<void> _rename(BuildContext context, LibraryProvider library) async {
    final controller = TextEditingController(text: preset.label ?? '');
    final newLabel = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newLabel != null) {
      await library.renameCoverPreset(preset, newLabel);
    }
  }

  Future<void> _confirmDelete(BuildContext context, LibraryProvider library) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete preset?'),
        content: Text(
          'Delete "${preset.label ?? 'this cover preset'}"? Its photos will '
          'be removed too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await library.deleteCoverPreset(preset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    preset.label ?? 'Untitled preset',
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (preset.isActive)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Chip(
                      label: Text('On shelf'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _editPhotos(context),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  _Thumb(path: preset.frontImagePath, label: 'Front'),
                  const SizedBox(width: 8),
                  _Thumb(path: preset.spineImagePath, label: 'Spine'),
                  const SizedBox(width: 8),
                  _Thumb(path: preset.backImagePath, label: 'Back'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tap the photos to add or replace any of them.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!preset.isActive)
                  TextButton(
                    onPressed: () =>
                        library.setActiveCoverPreset(preset.bookId, preset.id!),
                    child: const Text('Use on shelf'),
                  ),
                IconButton(
                  icon: const Icon(Icons.drive_file_rename_outline, size: 20),
                  onPressed: () => _rename(context, library),
                  tooltip: 'Rename',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context, library),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.label});

  final String? path;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 0.72,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias,
              child: path == null
                  ? const Icon(Icons.image_not_supported_outlined, size: 20)
                  : (isRemoteImagePath(path!)
                      ? Image.network(path!, fit: BoxFit.cover)
                      : Image.file(File(path!), fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
