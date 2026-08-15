import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/cover_preset.dart';
import '../services/document_scanner_service.dart';
import '../services/image_storage_service.dart';
import '../state/library_provider.dart';
import '../widgets/full_image_viewer.dart';

enum _CoverSlot { front, spine, back }

extension on _CoverSlot {
  String label(AppLocalizations t) => switch (this) {
        _CoverSlot.front => t.coverSlotFront,
        _CoverSlot.spine => t.coverSlotSpine,
        _CoverSlot.back => t.coverSlotBack,
      };
}

/// One image slot's editing state. [originalPath] is what this slot was
/// actually persisted as before this edit session (null for a brand-new
/// preset, or an existing preset's saved local path/URL) — kept around
/// purely so a saved-to-disk file can be deleted if this edit replaces or
/// clears it. [basePath] is the slot's current value absent a fresh pick:
/// initially the same as [originalPath], but reassigned directly by the
/// "use API cover" shortcut. Picking a new photo sets [pickedFile] (which
/// takes precedence for both preview and saving); [cleared] means the user
/// explicitly removed whatever was there.
class _SlotState {
  _SlotState({this.originalPath}) : basePath = originalPath;

  final String? originalPath;
  String? basePath;
  XFile? pickedFile;
  bool cleared = false;

  bool get hasImage => !cleared && (pickedFile != null || basePath != null);
}

/// Captures (or picks from the gallery) a front-cover/spine/back-cover
/// photo set for [book]. With no [existingPreset], this always creates a
/// new [BookCoverPreset] — a book can have several. Pass [existingPreset]
/// to come back and fill in slots that were skipped earlier, replace one,
/// or clear it; every slot is optional either way.
class CoverScanScreen extends StatefulWidget {
  const CoverScanScreen({super.key, required this.book, this.existingPreset});

  final Book book;
  final BookCoverPreset? existingPreset;

  @override
  State<CoverScanScreen> createState() => _CoverScanScreenState();
}

enum _CoverSource { scan, gallery }

class _CoverScanScreenState extends State<CoverScanScreen> {
  final _picker = ImagePicker();
  final _documentScanner = DocumentScannerService();
  late final TextEditingController _labelController;
  late final Map<_CoverSlot, _SlotState> _slots;

  bool _saving = false;

  bool get _isEditing => widget.existingPreset != null;

  bool get _hasAnyImage => _slots.values.any((s) => s.hasImage);

  @override
  void initState() {
    super.initState();
    final preset = widget.existingPreset;
    _labelController = TextEditingController(text: preset?.label ?? '');
    _slots = {
      _CoverSlot.front: _SlotState(originalPath: preset?.frontImagePath),
      _CoverSlot.spine: _SlotState(originalPath: preset?.spineImagePath),
      _CoverSlot.back: _SlotState(originalPath: preset?.backImagePath),
    };
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _frontIsApiCoverAlready {
    final front = _slots[_CoverSlot.front]!;
    return front.pickedFile == null &&
        !front.cleared &&
        front.basePath == widget.book.thumbnailUrl;
  }

  bool get _canUseApiCover =>
      widget.book.thumbnailUrl != null && !_frontIsApiCoverAlready;

  Future<void> _pickImage(_CoverSlot slot) async {
    final t = AppLocalizations.of(context);
    final source = await showModalBottomSheet<_CoverSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(t.scanDocument),
              subtitle: Text(t.scanDocumentSubtitle),
              onTap: () => Navigator.of(ctx).pop(_CoverSource.scan),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.chooseFromGallery),
              onTap: () => Navigator.of(ctx).pop(_CoverSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    if (source == _CoverSource.scan) {
      await _scanDocument(slot);
      return;
    }

    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;

    setState(() {
      final s = _slots[slot]!;
      s.pickedFile = file;
      s.cleared = false;
    });
  }

  Future<void> _scanDocument(_CoverSlot slot) async {
    String? path;
    try {
      path = await _documentScanner.scanSinglePage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).documentScanFailed('$e'))),
      );
      return;
    }
    if (path == null || !mounted) return;

    setState(() {
      final s = _slots[slot]!;
      s.pickedFile = XFile(path!);
      s.cleared = false;
    });
  }

  void _clearSlot(_CoverSlot slot) {
    setState(() {
      final s = _slots[slot]!;
      s.pickedFile = null;
      s.cleared = true;
    });
  }

  void _useApiCoverForFront() {
    setState(() {
      final s = _slots[_CoverSlot.front]!;
      s.basePath = widget.book.thumbnailUrl;
      s.pickedFile = null;
      s.cleared = false;
    });
  }

  /// Resolves a slot to its final path for saving: a freshly picked photo
  /// is copied into local storage (replacing whatever local file used to
  /// be there), a cleared slot becomes null (deleting any old local file),
  /// switching to the API cover shortcut deletes whatever local file it
  /// replaces, and an untouched slot just keeps its current value.
  Future<String?> _resolveSlot(_CoverSlot slot, int bookId) async {
    final state = _slots[slot]!;
    final storage = ImageStorageService.instance;

    if (state.cleared) {
      await storage.deleteFile(state.originalPath);
      return null;
    }
    if (state.pickedFile != null) {
      final newPath = await storage.saveCoverImage(bookId, state.pickedFile!);
      await storage.deleteFile(state.originalPath);
      return newPath;
    }
    if (state.basePath != state.originalPath) {
      await storage.deleteFile(state.originalPath);
    }
    return state.basePath;
  }

  Future<void> _save() async {
    if (!_hasAnyImage || widget.book.id == null || _saving) return;
    setState(() => _saving = true);

    final library = context.read<LibraryProvider>();
    final bookId = widget.book.id!;

    final frontPath = await _resolveSlot(_CoverSlot.front, bookId);
    final spinePath = await _resolveSlot(_CoverSlot.spine, bookId);
    final backPath = await _resolveSlot(_CoverSlot.back, bookId);
    final label = _labelController.text.trim();

    if (_isEditing) {
      await library.updateCoverPreset(
        widget.existingPreset!.copyWith(
          label: label.isEmpty ? null : label,
          clearLabel: label.isEmpty,
          frontImagePath: frontPath,
          clearFrontImagePath: frontPath == null,
          spineImagePath: spinePath,
          clearSpineImagePath: spinePath == null,
          backImagePath: backPath,
          clearBackImagePath: backPath == null,
        ),
      );
    } else {
      await library.addCoverPreset(
        BookCoverPreset(
          bookId: bookId,
          label: label.isEmpty ? null : label,
          frontImagePath: frontPath,
          spineImagePath: spinePath,
          backImagePath: backPath,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? t.editCoverPresetTitle : t.scanCoverTitle),
        actions: [
          TextButton(
            onPressed: _hasAnyImage && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.coverSlotsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _SlotTile(
            slot: _CoverSlot.front,
            state: _slots[_CoverSlot.front]!,
            onTap: () => _pickImage(_CoverSlot.front),
            onClear: () => _clearSlot(_CoverSlot.front),
          ),
          if (_canUseApiCover)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _useApiCoverForFront,
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: Text(t.useApiCoverForFront),
              ),
            ),
          const SizedBox(height: 16),
          _SlotTile(
            slot: _CoverSlot.spine,
            state: _slots[_CoverSlot.spine]!,
            onTap: () => _pickImage(_CoverSlot.spine),
            onClear: () => _clearSlot(_CoverSlot.spine),
          ),
          const SizedBox(height: 16),
          _SlotTile(
            slot: _CoverSlot.back,
            state: _slots[_CoverSlot.back]!,
            onTap: () => _pickImage(_CoverSlot.back),
            onClear: () => _clearSlot(_CoverSlot.back),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: t.presetLabelField,
              hintText: t.presetLabelHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.state,
    required this.onTap,
    required this.onClear,
  });

  final _CoverSlot slot;
  final _SlotState state;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pickedFile = state.pickedFile;
    final basePath = state.cleared ? null : state.basePath;
    final hasImage = pickedFile != null || basePath != null;
    final previewPath = pickedFile?.path ?? basePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slot.label(t),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: hasImage
              ? () => showFullImagePreview(context, previewPath!)
              : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!hasImage)
                  const Center(child: Icon(Icons.add_a_photo_outlined, size: 32))
                else if (pickedFile != null)
                  Image.file(File(pickedFile.path), fit: BoxFit.cover)
                else if (isRemoteImagePath(basePath!))
                  Image.network(basePath, fit: BoxFit.cover)
                else
                  Image.file(File(basePath), fit: BoxFit.cover),
                if (hasImage) ...[
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _ClearButton(onPressed: onClear),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: _ReplaceButton(onPressed: onTap, tooltip: t.replaceTooltip),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 18),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ReplaceButton extends StatelessWidget {
  const _ReplaceButton({required this.onPressed, required this.tooltip});

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
