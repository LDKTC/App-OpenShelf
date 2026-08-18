import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/book_page.dart';
import '../services/document_scanner_service.dart';
import '../services/image_storage_service.dart';
import '../state/library_provider.dart';
import '../widgets/app_image.dart';

enum _PageSource { scan, gallery }

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
  final _documentScanner = DocumentScannerService();
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
    final t = AppLocalizations.of(context);
    final source = await showModalBottomSheet<_PageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The document scanner needs Google Play services and isn't
            // available on web.
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: Text(t.scanDocument),
                subtitle: Text(t.scanDocumentSubtitle),
                onTap: () => Navigator.of(ctx).pop(_PageSource.scan),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.chooseFromGallery),
              onTap: () => Navigator.of(ctx).pop(_PageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    if (source == _PageSource.scan) {
      await _scanDocument();
      return;
    }

    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _file = file);
  }

  Future<void> _scanDocument() async {
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
    setState(() => _file = XFile(path!));
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
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.savePageTitle),
        actions: [
          TextButton(
            onPressed: _file != null && !_saving ? _save : null,
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
            t.savePageHint,
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
                  : AppImage(_file!.path, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: t.pageLabelField,
              hintText: t.pageLabelHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: t.noteField),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
