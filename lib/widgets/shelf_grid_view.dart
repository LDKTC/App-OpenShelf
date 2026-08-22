import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../services/settings_service.dart';
import '../state/library_grouping.dart';
import '../state/library_provider.dart';
import 'book_preview_sheet.dart';
import 'book_shelf_tile.dart';
import 'section_header.dart';

/// The "visual bookshelf" view of [LibraryProvider.filteredBooks]: each
/// book renders as its cover or spine (per the global shelf display mode),
/// falling back to a text info tile when it has no matching preset image.
///
/// When the current sort field groups books (series, language/genre, or the
/// date added), the shelf splits into one section per group: each section
/// shows its label followed by a single scrollable row of books, which
/// slides sideways instead of wrapping once it has more books than fit the
/// screen width. Sort fields that don't group (title/author/publisher/ISBN)
/// keep the flat, wrapping shelf layout.
class ShelfGridView extends StatelessWidget {
  const ShelfGridView({super.key, required this.onTapBook});

  final void Function(int bookId) onTapBook;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final books = library.filteredBooks;
    final mode = library.shelfDisplayMode;
    final t = AppLocalizations.of(context);

    if (books.isEmpty) {
      return Center(child: Text(t.noBooksYet));
    }

    void previewBook(Book book) => showBookPreview(
          context,
          book: book,
          coverImagePath: library.activeCoverPresetFor(book.id!)?.frontImagePath,
          currentStatus: library.currentStampFor(book.id!)?.type,
          onOpenDetails: () => onTapBook(book.id!),
        );

    final sections = buildBookSections(books, library.sortField, t);
    final isGrouped = sections.length > 1 || sections.first.label != null;

    if (!isGrouped) {
      if (mode == ShelfDisplayMode.spine) {
        return SpineShelfView(
          books: books,
          presetFor: (bookId) => library.activeCoverPresetFor(bookId),
          statusFor: (bookId) => library.currentStampFor(bookId)?.type,
          onTapBook: onTapBook,
          onLongPressBook: (bookId) =>
              previewBook(books.firstWhere((b) => b.id == bookId)),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.68,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookShelfTile(
            book: book,
            activePreset: library.activeCoverPresetFor(book.id!),
            currentStatus: library.currentStampFor(book.id!)?.type,
            mode: mode,
            onTap: () => onTapBook(book.id!),
            onLongPress: () => previewBook(book),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(label: section.label!),
              const SizedBox(height: 8),
              if (mode == ShelfDisplayMode.spine)
                SpineShelfRow(
                  books: section.books,
                  presetFor: (bookId) => library.activeCoverPresetFor(bookId),
                  statusFor: (bookId) => library.currentStampFor(bookId)?.type,
                  onTapBook: onTapBook,
                  onLongPressBook: (bookId) => previewBook(
                    section.books.firstWhere((b) => b.id == bookId),
                  ),
                )
              else
                CoverShelfRow(
                  books: section.books,
                  activePresetFor: (bookId) =>
                      library.activeCoverPresetFor(bookId),
                  statusFor: (bookId) => library.currentStampFor(bookId)?.type,
                  onTapBook: onTapBook,
                  onLongPressBook: (bookId) => previewBook(
                    section.books.firstWhere((b) => b.id == bookId),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
