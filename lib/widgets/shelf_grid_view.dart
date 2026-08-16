import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../state/library_provider.dart';
import 'book_shelf_tile.dart';

/// The "visual bookshelf" view of [LibraryProvider.filteredBooks]: each
/// book renders as its cover or spine (per the global shelf display mode),
/// falling back to a text info tile when it has no matching preset image.
class ShelfGridView extends StatelessWidget {
  const ShelfGridView({super.key, required this.onTapBook});

  final void Function(int bookId) onTapBook;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final books = library.filteredBooks;
    final mode = library.shelfDisplayMode;

    if (books.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noBooksYet));
    }

    if (mode == ShelfDisplayMode.spine) {
      return SpineShelfView(
        books: books,
        presetFor: (bookId) => library.activeCoverPresetFor(bookId),
        statusFor: (bookId) => library.currentStampFor(bookId)?.type,
        onTapBook: onTapBook,
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
        );
      },
    );
  }
}
