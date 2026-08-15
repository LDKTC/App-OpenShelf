import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/book_page.dart';
import '../services/image_storage_service.dart';
import '../state/library_provider.dart';

/// Captures (or picks from the gallery) a photo of a page or illustration
/// inside [book] and saves it as a [BookPage] "reminder" — something the
/// user wants to find again later without re-reading the whole book.
class PageScanScreen extends StatefulWidget {
  const PageScanScreen({super.key, required this.book});

  final Book book;

  @override
  State<PageScanScreen> createState() => _PageScanScreenState();
}

class _PageScanScreenState extends State<PageScanScreen> {
  final _picker = ImagePicker();
  final _labelController = TextEditingController();
  final _noteController = TextEditingController();

  XFile? _file;
  bool _saving = false;

  @override
  void dispose() {
    _labelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _showSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _file = file);
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null || widget.book.id == null || _saving) return;
    setState(() => _saving = true);

    final library = context.read<LibraryProvider>();
    final bookId = widget.book.id!;
    final path = await ImageStorageService.instance.savePageImage(bookId, file);

    final label = _labelController.text.trim();
    final note = _noteController.text.trim();
    await library.addBookPage(
      BookPage(
        bookId: bookId,
        imagePath: path,
        pageLabel: label.isEmpty ? null : label,
        note: note.isEmpty ? null : note,
        createdAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save a page'),
        actions: [
          TextButton(
            onPressed: _file != null && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Photograph a page or illustration to keep as a reminder inside '
            'the app.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _showSourceSheet,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: _file == null
                  ? const Center(child: Icon(Icons.add_a_photo_outlined, size: 40))
                  : Image.file(File(_file!.path), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Page label (optional)',
              hintText: 'e.g. p.128 or "map illustration"',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
