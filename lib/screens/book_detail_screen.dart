import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/cover_preset.dart';
import '../services/image_storage_service.dart';
import '../state/library_provider.dart';
import '../widgets/book_3d_cover.dart';
import '../widgets/full_image_viewer.dart';
import '../widgets/stamp_timeline.dart';
import '../widgets/status_chip.dart';
import 'book_edit_screen.dart';
import 'book_pages_screen.dart';
import 'cover_presets_screen.dart';
import 'page_scan_screen.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final book = library.getById(bookId);
    final t = AppLocalizations.of(context);

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(t.bookRemovedMessage)),
      );
    }

    final categoryIds = library.categoryIdsFor(bookId).toSet();
    final categories =
        library.categories.where((c) => categoryIds.contains(c.id)).toList();
    final activePreset = library.activeCoverPresetFor(bookId);
    final pages = library.pagesFor(bookId);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookEditScreen(existingBook: book),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  final t = AppLocalizations.of(ctx);
                  return AlertDialog(
                    title: Text(t.removeBookTitle),
                    content: Text(t.deleteBookConfirm(book.title)),
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
                await library.deleteBook(bookId);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                height: 140,
                child: _CoverArt(book: book, activePreset: activePreset),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: Theme.of(context).textTheme.titleLarge),
                    if (book.series != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.seriesVolumeDisplay != null
                            ? t.seriesWithVolume(
                                book.series!, book.seriesVolumeDisplay!)
                            : book.series!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(book.authorsDisplay, style: Theme.of(context).textTheme.bodyMedium),
                    if (book.illustrators.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        t.illustratedBy(book.illustrators.join(', ')),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (book.publisher != null || book.publishedDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [book.publisher, book.publishedDate]
                            .whereType<String>()
                            .join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (book.isbn13 != null) ...[
                      const SizedBox(height: 4),
                      Text(t.isbnLabel(book.isbn13!), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CoverPresetsScreen(book: book)),
            ),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(activePreset == null ? t.scanCoverLabel : t.manageCoversLabel),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.readingStatusLabel, style: Theme.of(context).textTheme.labelLarge),
              StatusChip(currentType: library.currentStampFor(bookId)?.type),
            ],
          ),
          const SizedBox(height: 8),
          StampTimeline(bookId: bookId),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.categoriesLabel, style: Theme.of(context).textTheme.labelLarge),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: t.editCategoriesTooltip,
                visualDensity: VisualDensity.compact,
                onPressed: () => _pickCategories(context, bookId, categoryIds),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (categories.isEmpty)
            Text(
              t.noCategoriesAssignedHint,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              children: [for (final c in categories) Chip(label: Text(c.name))],
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.savedPagesLabel, style: Theme.of(context).textTheme.labelLarge),
              if (pages.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BookPagesScreen(book: book)),
                  ),
                  child: Text(t.viewAllLabel),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (pages.isEmpty)
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PageScanScreen(book: book)),
              ),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(t.savePageTitle),
            )
          else
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pages.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == pages.length) {
                    return _AddPageTile(book: book);
                  }
                  final page = pages[index];
                  return InkWell(
                    onTap: () =>
                        showFullImagePreview(context, page.imagePath),
                    borderRadius: BorderRadius.circular(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(page.imagePath),
                        width: 72,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 72,
                          height: 96,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (book.description != null) ...[
            const SizedBox(height: 20),
            Text(t.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(book.description!),
          ],
          if (book.notes != null) ...[
            const SizedBox(height: 20),
            Text(t.myNotesLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(book.notes!),
          ],
          if (book.source != null) ...[
            const SizedBox(height: 20),
            Text(
              t.sourceLabel(book.source!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _pickCategories(
  BuildContext context,
  int bookId,
  Set<int> currentIds,
) async {
  final result = await showDialog<Set<int>>(
    context: context,
    builder: (_) => _CategoryPickerDialog(initialSelectedIds: currentIds),
  );
  if (result != null && context.mounted) {
    await context.read<LibraryProvider>().setBookCategories(bookId, result.toList());
  }
}

class _CategoryPickerDialog extends StatefulWidget {
  const _CategoryPickerDialog({required this.initialSelectedIds});

  final Set<int> initialSelectedIds;

  @override
  State<_CategoryPickerDialog> createState() => _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends State<_CategoryPickerDialog> {
  late final Set<int> _selectedIds = {...widget.initialSelectedIds};

  Future<void> _addNewCategory(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final t = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(t.newCategoryTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: t.categoryNameField),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(t.add),
            ),
          ],
        );
      },
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      final id = await context.read<LibraryProvider>().addCategory(name);
      if (mounted) setState(() => _selectedIds.add(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.selectCategoriesTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: library.categories.isEmpty
            ? Text(t.noCategoriesYet)
            : SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in library.categories)
                      FilterChip(
                        label: Text(category.name),
                        selected: _selectedIds.contains(category.id),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedIds.add(category.id!);
                          } else {
                            _selectedIds.remove(category.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _addNewCategory(context),
          icon: const Icon(Icons.add, size: 18),
          label: Text(t.newCategoryTitle),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          child: Text(t.save),
        ),
      ],
    );
  }
}

class _CoverArt extends StatelessWidget {
  const _CoverArt({required this.book, required this.activePreset});

  final Book book;
  final BookCoverPreset? activePreset;

  /// Tapping the cover shows it full-screen: a proper 3D mockup when there's
  /// a cover preset with at least one scanned face, or a plain zoomable
  /// preview of the flat API thumbnail otherwise.
  void _open(BuildContext context) {
    final preset = activePreset;
    if (preset != null && !preset.isEmpty) {
      showBook3DPreview(context, preset);
      return;
    }
    final thumbnailUrl = book.thumbnailUrl;
    if (thumbnailUrl != null) {
      showFullImagePreview(context, thumbnailUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.menu_book_outlined, size: 32),
    );

    Widget image;
    final frontPath = activePreset?.frontImagePath;
    if (frontPath != null) {
      image = isRemoteImagePath(frontPath)
          ? Image.network(
              frontPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            )
          : Image.file(
              File(frontPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            );
    } else if (book.thumbnailUrl != null) {
      image = Image.network(
        book.thumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else {
      image = placeholder;
    }

    return InkWell(onTap: () => _open(context), child: image);
  }
}

class _AddPageTile extends StatelessWidget {
  const _AddPageTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PageScanScreen(book: book)),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 72,
        height: 96,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }
}
