import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/cover_preset.dart';
import '../services/image_storage_service.dart';
import '../state/library_provider.dart';
import '../widgets/full_image_viewer.dart';
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
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.bookCoversTitle)),
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
        label: Text(t.scanNewPresetLabel),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
              t.noCoversYet,
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

  /// Tapping a thumbnail that already has a photo shows it immediately;
  /// an empty slot instead opens the edit screen to fill it in.
  void _openThumb(BuildContext context, String? path) {
    if (path != null) {
      showFullImagePreview(context, path);
    } else {
      _editPhotos(context);
    }
  }

  Future<void> _rename(BuildContext context, LibraryProvider library) async {
    final controller = TextEditingController(text: preset.label ?? '');
    final newLabel = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final t = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(t.renamePresetTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: t.renamePresetLabelField),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(t.save),
            ),
          ],
        );
      },
    );
    if (newLabel != null) {
      await library.renameCoverPreset(preset, newLabel);
    }
  }

  Future<void> _confirmDelete(BuildContext context, LibraryProvider library) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(t.deletePresetTitle),
          content: Text(t.deletePresetConfirm(preset.label ?? t.thisCoverPreset)),
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
        );
      },
    );
    if (confirmed == true) {
      await library.deleteCoverPreset(preset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryProvider>();
    final t = AppLocalizations.of(context);
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
                    preset.label ?? t.untitledPresetLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (preset.isActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: Text(t.onShelfLabel),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Thumb(
                  path: preset.frontImagePath,
                  label: t.coverThumbFront,
                  onTap: () => _openThumb(context, preset.frontImagePath),
                ),
                const SizedBox(width: 8),
                _Thumb(
                  path: preset.spineImagePath,
                  label: t.coverThumbSpine,
                  onTap: () => _openThumb(context, preset.spineImagePath),
                ),
                const SizedBox(width: 8),
                _Thumb(
                  path: preset.backImagePath,
                  label: t.coverThumbBack,
                  onTap: () => _openThumb(context, preset.backImagePath),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.tapPhotosHint,
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
                    child: Text(t.useOnShelfLabel),
                  ),
                IconButton(
                  icon: const Icon(Icons.photo_camera_back_outlined, size: 20),
                  onPressed: () => _editPhotos(context),
                  tooltip: t.editPhotosTooltip,
                ),
                IconButton(
                  icon: const Icon(Icons.drive_file_rename_outline, size: 20),
                  onPressed: () => _rename(context, library),
                  tooltip: t.renameTooltip,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context, library),
                  tooltip: t.delete,
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
  const _Thumb({required this.path, required this.label, required this.onTap});

  final String? path;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 0.72,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                // BoxFit.contain (not cover): a narrow spine photo should
                // show in full, auto-scaled to fit the box, rather than
                // being cropped to this cell's front-cover-ish aspect ratio.
                child: path == null
                    ? const Icon(Icons.image_not_supported_outlined, size: 20)
                    : (isRemoteImagePath(path!)
                        ? Image.network(path!, fit: BoxFit.contain)
                        : Image.file(File(path!), fit: BoxFit.contain)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
