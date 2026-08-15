import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/book_lookup_service.dart';
import '../state/library_provider.dart';
import 'book_detail_screen.dart';
import 'book_edit_screen.dart';

/// Add (or find) a book by typing its ISBN instead of scanning the
/// barcode — the same lookup the scan flow uses, just text-entry driven.
class IsbnEntryScreen extends StatefulWidget {
  const IsbnEntryScreen({super.key});

  @override
  State<IsbnEntryScreen> createState() => _IsbnEntryScreenState();
}

class _IsbnEntryScreenState extends State<IsbnEntryScreen> {
  final _controller = TextEditingController();
  final _lookupService = BookLookupService();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final library = context.read<LibraryProvider>();
    final result = await _lookupService.resolve(raw, library);
    if (!mounted) return;

    switch (result) {
      case IsbnLookupInvalid():
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).invalidIsbnError(raw);
        });
      case IsbnLookupExisting(:final book):
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id!)),
        );
      case IsbnLookupMetadata(:final metadata):
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BookEditScreen(metadata: metadata)),
        );
      case IsbnLookupNotFound(:final isbn13):
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BookEditScreen(prefillIsbn13: isbn13)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.enterIsbnTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.enterIsbnBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.text,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.isbnField,
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.lookUp),
            ),
          ],
        ),
      ),
    );
  }
}
