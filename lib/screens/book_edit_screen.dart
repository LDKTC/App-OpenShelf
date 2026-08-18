import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/book_metadata.dart';
import '../models/cover_preset.dart';
import '../services/image_storage_service.dart';
import '../services/ocr_service.dart';
import '../state/library_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/suggestion_text_field.dart';
import 'book_detail_screen.dart';

/// Add or edit a book. Can be pre-filled from a metadata lookup, a bare
/// scanned ISBN with no metadata match, a photographed cover (via
/// [scannedCoverPath], from scan-cover-first), or opened empty for a fully
/// manual entry. Pass [existingBook] to edit a book already in the library
/// instead of creating a new one.
class BookEditScreen extends StatefulWidget {
  const BookEditScreen({
    super.key,
    this.metadata,
    this.prefillIsbn13,
    this.existingBook,
    this.scannedCoverPath,
  });

  final BookMetadata? metadata;
  final String? prefillIsbn13;
  final Book? existingBook;

  /// Local file path of a cover photo captured before this book existed
  /// (the scan-cover-first flow). Saved into permanent storage as the
  /// book's first cover preset once it's created.
  final String? scannedCoverPath;

  @override
  State<BookEditScreen> createState() => _BookEditScreenState();
}

class _BookEditScreenState extends State<BookEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _authors;
  late final TextEditingController _illustrators;
  late final TextEditingController _series;
  late final TextEditingController _seriesVolume;
  late final TextEditingController _genre;
  late final TextEditingController _language;
  late final TextEditingController _publisher;
  late final TextEditingController _publishedDate;
  late final TextEditingController _isbn13;
  late final TextEditingController _description;
  late final TextEditingController _pageCount;
  late final TextEditingController _notes;

  final _ocrService = OcrService();
  final _ocrPicker = ImagePicker();
  bool _scanningField = false;

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
    _illustrators = TextEditingController(
      text: (book?.illustrators ?? metadata?.illustrators ?? const [])
          .join(', '),
    );
    _series = TextEditingController(text: book?.series ?? '');
    _seriesVolume =
        TextEditingController(text: book?.seriesVolumeDisplay ?? '');
    _genre = TextEditingController(text: book?.genre ?? '');
    _language = TextEditingController(text: book?.language ?? metadata?.language ?? '');
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
    _illustrators.dispose();
    _series.dispose();
    _seriesVolume.dispose();
    _genre.dispose();
    _language.dispose();
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
    final illustrators = _illustrators.text
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
      illustrators: illustrators,
      series: _series.text.trim().isEmpty ? null : _series.text.trim(),
      seriesVolume: double.tryParse(_seriesVolume.text.trim()),
      genre: _genre.text.trim().isEmpty ? null : _genre.text.trim(),
      publisher: _publisher.text.trim().isEmpty ? null : _publisher.text.trim(),
      publishedDate: _publishedDate.text.trim().isEmpty ? null : _publishedDate.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      pageCount: int.tryParse(_pageCount.text.trim()),
      thumbnailUrl: _thumbnailUrl,
      language: _language.text.trim().isEmpty ? null : _language.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      source: widget.existingBook?.source ?? widget.metadata?.source ?? 'manual',
      dateAdded: widget.existingBook?.dateAdded ?? DateTime.now(),
    );

    if (_isEditing) {
      await library.updateBook(book, categoryIds: _selectedCategoryIds.toList());
      if (!mounted) return;
      // Editing always opens from that book's own BookDetailScreen, which
      // already watches the provider and will show the saved changes as
      // soon as we pop back to it — no need to push a second copy of it.
      Navigator.of(context).pop();
      return;
    }

    final bookId =
        await library.addBook(book, categoryIds: _selectedCategoryIds.toList());

    final scannedCoverPath = widget.scannedCoverPath;
    if (scannedCoverPath != null) {
      final savedPath = await ImageStorageService.instance
          .saveCoverImage(bookId, XFile(scannedCoverPath));
      await library.addCoverPreset(
        BookCoverPreset(
          bookId: bookId,
          frontImagePath: savedPath,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
    );
  }

  /// Photographs [fieldLabel]'s text, runs OCR on it, then shows the
  /// recognized text back to the user for review — nothing is written into
  /// [controller] unless they explicitly approve it (editing it first if
  /// needed), so a bad scan never silently overwrites what's there.
  Future<void> _scanIntoField(
    TextEditingController controller,
    String fieldLabel,
  ) async {
    if (_scanningField) return;
    setState(() => _scanningField = true);
    try {
      final photo = await _ocrPicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (photo == null || !mounted) return;

      String recognized;
      try {
        recognized = await _ocrService.recognizeText(photo);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).textScanFailed('$e'))),
        );
        return;
      }
      if (!mounted) return;

      final approved = await showDialog<String>(
        context: context,
        builder: (_) => _OcrReviewDialog(
          fieldLabel: fieldLabel,
          recognizedText: recognized,
        ),
      );
      if (approved != null) controller.text = approved;
    } finally {
      if (mounted) setState(() => _scanningField = false);
    }
  }

  Widget _scanButton(String fieldLabel, TextEditingController controller) {
    final t = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.document_scanner_outlined),
      tooltip: t.scanFieldTooltip(fieldLabel),
      onPressed:
          _scanningField ? null : () => _scanIntoField(controller, fieldLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? t.editBookTitle : t.addBookTitle),
        actions: [
          TextButton(onPressed: _save, child: Text(t.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.scannedCoverPath != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(widget.scannedCoverPath!, height: 140),
                  ),
                ),
              )
            else if (_thumbnailUrl != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image.network(_thumbnailUrl!, height: 140),
                ),
              ),
            SuggestionTextField(
              controller: _title,
              suggestions: library.knownTitles,
              decoration: InputDecoration(
                labelText: t.titleField,
                suffixIcon: _scanButton(t.titleField, _title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.titleRequiredError : null,
            ),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _authors,
              suggestions: library.knownAuthors,
              multiValue: true,
              decoration: InputDecoration(
                labelText: t.authorsField,
                suffixIcon: _scanButton(t.authorsField, _authors),
              ),
            ),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _illustrators,
              suggestions: library.knownIllustrators,
              multiValue: true,
              decoration: InputDecoration(
                labelText: t.illustratorsField,
                suffixIcon: _scanButton(t.illustratorsField, _illustrators),
              ),
            ),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _series,
              suggestions: library.knownSeries,
              decoration: InputDecoration(labelText: t.seriesField),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _seriesVolume,
              decoration: InputDecoration(
                labelText: t.seriesVolumeField,
                hintText: t.seriesVolumeHint,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _genre,
              suggestions: library.knownGenres,
              decoration: InputDecoration(
                labelText: t.genreField,
                hintText: t.genreHint,
              ),
            ),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _language,
              suggestions: library.knownLanguages,
              decoration: InputDecoration(
                labelText: t.languageField,
                hintText: t.languageHint,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isbn13,
              decoration: InputDecoration(
                labelText: t.isbn13Field,
                suffixIcon: _scanButton(t.isbn13Field, _isbn13),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _publisher,
              suggestions: library.knownPublishers,
              decoration: InputDecoration(
                labelText: t.publisherField,
                suffixIcon: _scanButton(t.publisherField, _publisher),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _publishedDate,
              decoration: InputDecoration(labelText: t.publishedDateField),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pageCount,
              decoration: InputDecoration(labelText: t.pageCountField),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(labelText: t.descriptionField),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: t.myNotesField),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text(t.categoriesLabel, style: Theme.of(context).textTheme.labelLarge),
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

/// Shows the OCR text recognized from a scanned photo for [fieldLabel],
/// editable before it's applied — the approval gate that keeps a bad or
/// noisy scan from silently overwriting the field. Returns the approved
/// (possibly hand-edited) text via [Navigator.pop], or null if cancelled.
class _OcrReviewDialog extends StatefulWidget {
  const _OcrReviewDialog({required this.fieldLabel, required this.recognizedText});

  final String fieldLabel;
  final String recognizedText;

  @override
  State<_OcrReviewDialog> createState() => _OcrReviewDialogState();
}

class _OcrReviewDialogState extends State<_OcrReviewDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.recognizedText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.reviewScannedTitle(widget.fieldLabel)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recognizedText.isEmpty
                  ? t.ocrNoTextRecognized
                  : t.ocrEditAndFill(widget.fieldLabel),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 5,
              minLines: 1,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(t.useThisTextLabel),
        ),
      ],
    );
  }
}
