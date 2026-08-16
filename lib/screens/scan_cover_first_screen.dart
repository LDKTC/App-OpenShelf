import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/document_scanner_service.dart';
import 'book_edit_screen.dart';

enum _CoverSource { scan, gallery }

/// Starts adding a book by photographing its cover first — for books with
/// no barcode to scan or no ISBN match — then hands off to
/// [BookEditScreen] with the photo already attached so the title and other
/// details can be filled in manually.
class ScanCoverFirstScreen extends StatefulWidget {
  const ScanCoverFirstScreen({super.key});

  @override
  State<ScanCoverFirstScreen> createState() => _ScanCoverFirstScreenState();
}

class _ScanCoverFirstScreenState extends State<ScanCoverFirstScreen> {
  final _picker = ImagePicker();
  final _documentScanner = DocumentScannerService();

  XFile? _file;

  Future<void> _showSourceSheet() async {
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

  void _continue() {
    final file = _file;
    if (file == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookEditScreen(scannedCoverPath: file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.scanCoverFirstTitle),
        actions: [
          TextButton(
            onPressed: _file != null ? _continue : null,
            child: Text(t.continueLabel),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.scanCoverFirstHint,
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
          if (_file != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showSourceSheet,
              icon: const Icon(Icons.replay, size: 18),
              label: Text(t.retakeLabel),
            ),
          ],
        ],
      ),
    );
  }
}
