import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/book_metadata.dart';
import '../models/read_status.dart';
import '../state/library_provider.dart';
import 'book_detail_screen.dart';

/// Add or edit a book. Can be pre-filled from a metadata lookup, a bare
/// scanned ISBN with no metadata match, or opened empty for a fully
/// manual entry. Pass [existingBook] to edit a book already in the
/// library instead of creating a new one.
class BookEditScreen extends StatefulWidget {
  const BookEditScreen({
    super.key,
    this.metadata,
    this.prefillIsbn13,
    this.existingBook,
  });

  final BookMetadata? metadata;
  final String? prefillIsbn13;
  final Book? existingBook;

  @override
  State<BookEditScreen> createState() => _BookEditScreenState();
}

class _BookEditScreenState extends State<BookEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _authors;
  late final TextEditingController _publisher;
  late final TextEditingController _publishedDate;
  late final TextEditingController _isbn13;
  late final TextEditingController _description;
  late final TextEditingController _pageCount;
  late final TextEditingController _notes;

  ReadStatus _status = ReadStatus.unread;
  String? _thumbnailUrl;
  Set<int> _selectedCategoryIds = {};

  bool get _isEditing => widget.existingBook != null;

  @override
  void initState() {
    super.initState();
    final book = widget.existingBook;
    final metadata = widget.metadata;

    _title = TextEditingController(text: book?.title ?? metadata?.title ?? '');
    _authors = TextEditingController(
      text: (book?.authors ?? metadata?.authors ?? const []).join(', '),
    );
    _publisher = TextEditingController(text: book?.publisher ?? metadata?.publisher ?? '');
    _publishedDate = TextEditingController(
      text: book?.publishedDate ?? metadata?.publishedDate ?? '',
    );
    _isbn13 = TextEditingController(
      text: book?.isbn13 ?? metadata?.isbn13 ?? widget.prefillIsbn13 ?? '',
    );
    _description = TextEditingController(text: book?.description ?? metadata?.description ?? '');
    _pageCount = TextEditingController(
      text: (book?.pageCount ?? metadata?.pageCount)?.toString() ?? '',
    );
    _notes = TextEditingController(text: book?.notes ?? '');
    _status = book?.status ?? ReadStatus.unread;
    _thumbnailUrl = book?.thumbnailUrl ?? metadata?.thumbnailUrl;

    if (book != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final library = context.read<LibraryProvider>();
        final ids = library.categoryIdsFor(book.id!);
        if (mounted) setState(() => _selectedCategoryIds = ids.toSet());
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _authors.dispose();
    _publisher.dispose();
    _publishedDate.dispose();
    _isbn13.dispose();
    _description.dispose();
    _pageCount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final library = context.read<LibraryProvider>();

    final authors = _authors.text
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    final book = Book(
      id: widget.existingBook?.id,
      isbn13: _isbn13.text.trim().isEmpty ? null : _isbn13.text.trim(),
      isbn10: widget.existingBook?.isbn10 ?? widget.metadata?.isbn10,
      title: _title.text.trim(),
      authors: authors,
      publisher: _publisher.text.trim().isEmpty ? null : _publisher.text.trim(),
      publishedDate: _publishedDate.text.trim().isEmpty ? null : _publishedDate.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      pageCount: int.tryParse(_pageCount.text.trim()),
      thumbnailUrl: _thumbnailUrl,
      language: widget.existingBook?.language ?? widget.metadata?.language,
      status: _status,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      source: widget.existingBook?.source ?? widget.metadata?.source ?? 'manual',
      dateAdded: widget.existingBook?.dateAdded ?? DateTime.now(),
      dateStarted: widget.existingBook?.dateStarted,
      dateFinished: widget.existingBook?.dateFinished,
    );

    int bookId;
    if (_isEditing) {
      await library.updateBook(book, categoryIds: _selectedCategoryIds.toList());
      bookId = book.id!;
    } else {
      bookId = await library.addBook(book, categoryIds: _selectedCategoryIds.toList());
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Book' : 'Add Book'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_thumbnailUrl != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image.network(_thumbnailUrl!, height: 140),
                ),
              ),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _authors,
              decoration: const InputDecoration(labelText: 'Authors (comma-separated)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isbn13,
              decoration: const InputDecoration(labelText: 'ISBN-13'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _publisher,
              decoration: const InputDecoration(labelText: 'Publisher'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _publishedDate,
              decoration: const InputDecoration(labelText: 'Published date'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pageCount,
              decoration: const InputDecoration(labelText: 'Page count'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'My notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text('Reading status', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ReadStatus>(
              segments: [
                for (final status in ReadStatus.values)
                  ButtonSegment(value: status, label: Text(status.label)),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
            const SizedBox(height: 16),
            Text('Categories', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in library.categories)
                  FilterChip(
                    label: Text(category.name),
                    selected: _selectedCategoryIds.contains(category.id),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selectedCategoryIds.add(category.id!);
                      } else {
                        _selectedCategoryIds.remove(category.id);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
