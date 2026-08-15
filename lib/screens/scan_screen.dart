import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/book_metadata.dart';
import '../services/book_lookup_service.dart';
import '../services/isbn_utils.dart';
import '../state/library_provider.dart';
import 'book_detail_screen.dart';
import 'book_edit_screen.dart';

/// What a detected ISBN does once resolved.
enum ScanMode {
  /// Add the scanned book to the library (looking it up in metadata
  /// providers if it isn't already there).
  addBook,

  /// Search the existing library: jump straight to the matching book, or
  /// offer to add it if there's no match yet.
  search,
}

/// Camera view that scans a barcode, validates it as an ISBN, and either
/// adds the book (looking up its metadata) or searches the library for it,
/// depending on [mode].
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.mode = ScanMode.addBook});

  final ScanMode mode;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );
  final _lookupService = BookLookupService();

  bool _busy = false;
  String? _statusMessage;

  // Only used in ScanMode.search: the scanned ISBN wasn't in the library,
  // so offer to add it instead (carrying over any metadata already found).
  String? _searchMissIsbn13;
  BookMetadata? _searchMissMetadata;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isSearch => widget.mode == ScanMode.search;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || !IsbnUtils.isValidIsbn(raw)) return;
    final isbn13 = IsbnUtils.normalizeToIsbn13(raw)!;

    final library = context.read<LibraryProvider>();

    setState(() {
      _busy = true;
      _statusMessage = 'Looking up $raw...';
      _searchMissIsbn13 = null;
      _searchMissMetadata = null;
    });
    await _controller.stop();

    final result = await _lookupService.resolve(raw, library);
    if (!mounted) return;

    switch (result) {
      case IsbnLookupInvalid():
        setState(() {
          _busy = false;
          _statusMessage = null;
        });
        await _controller.start();

      case IsbnLookupExisting(:final book):
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id!)),
        );

      case IsbnLookupMetadata(:final metadata):
        if (_isSearch) {
          _showSearchMiss(isbn13, metadata: metadata);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => BookEditScreen(metadata: metadata)),
          );
        }

      case IsbnLookupNotFound():
        if (_isSearch) {
          _showSearchMiss(isbn13);
        } else {
          await _handleAddNotFound(isbn13);
        }
    }
  }

  void _showSearchMiss(String isbn13, {BookMetadata? metadata}) {
    setState(() {
      _busy = false;
      _searchMissMetadata = metadata;
      _searchMissIsbn13 = isbn13;
      _statusMessage = 'No book with ISBN $isbn13 in your library.';
    });
  }

  Future<void> _handleAddNotFound(String isbn13) async {
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
  }

  void _addSearchMissToLibrary() {
    final metadata = _searchMissMetadata;
    final isbn13 = _searchMissIsbn13;
    if (metadata != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BookEditScreen(metadata: metadata)),
      );
    } else if (isbn13 != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BookEditScreen(prefillIsbn13: isbn13)),
      );
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _busy = false;
      _statusMessage = null;
      _searchMissIsbn13 = null;
      _searchMissMetadata = null;
    });
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSearch ? 'Scan to search' : 'Scan ISBN'),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_busy)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          Expanded(child: Text(_statusMessage!)),
                        ],
                      ),
                      if (_searchMissIsbn13 != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _scanAgain,
                              child: const Text('Scan again'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _addSearchMissToLibrary,
                              child: const Text('Add to library'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _isSearch
                        ? 'Scan a book already on your shelf to jump to it.'
                        : 'Point the camera at the barcode on the back of the book.',
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
