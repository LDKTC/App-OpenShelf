import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/book_metadata.dart';
import '../services/book_metadata_service.dart';
import '../services/isbn_utils.dart';
import '../state/library_provider.dart';
import 'book_detail_screen.dart';
import 'book_edit_screen.dart';

/// Camera view that scans a barcode, validates it as an ISBN, looks up
/// its metadata, and hands off to [BookEditScreen] for the user to
/// confirm before it's saved.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );
  final _metadataService = BookMetadataService();

  bool _busy = false;
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || !IsbnUtils.isValidIsbn(raw)) return;

    final library = context.read<LibraryProvider>();

    setState(() {
      _busy = true;
      _statusMessage = 'Looking up $raw...';
    });
    await _controller.stop();

    final isbn13 = IsbnUtils.normalizeToIsbn13(raw)!;

    final existing = await library.findByIsbn(isbn13);
    if (existing != null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: existing.id!),
        ),
      );
      return;
    }

    BookMetadata? metadata;
    try {
      metadata = await _metadataService.lookup(isbn13);
    } catch (_) {
      metadata = null;
    }

    if (!mounted) return;

    if (metadata == null) {
      setState(() {
        _statusMessage =
            'No metadata found for $isbn13. You can still add it manually.';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookEditScreen(prefillIsbn13: isbn13),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookEditScreen(metadata: metadata),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan ISBN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _ScannerOverlay(),
          if (_statusMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      Expanded(child: Text(_statusMessage!)),
                    ],
                  ),
                ),
              ),
            )
          else
            const Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Point the camera at the barcode on the back of the book.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
