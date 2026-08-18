import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/book_page.dart';
import '../state/library_provider.dart';
import '../widgets/app_image.dart';
import 'page_scan_screen.dart';

/// Gallery of every page/illustration saved as a reminder for [book].
class BookPagesScreen extends StatelessWidget {
  const BookPagesScreen({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final pages = library.pagesFor(book.id!);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.savedPagesTitle)),
      body: pages.isEmpty
          ? const _EmptyState()
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                return _PageThumb(
                  page: page,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => _PageDetailScreen(page: page)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PageScanScreen(book: book)),
        ),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(t.addPageLabel),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              t.noSavedPagesYet,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageThumb extends StatelessWidget {
  const _PageThumb({required this.page, required this.onTap});

  final BookPage page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AppImage(
          page.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

class _PageDetailScreen extends StatelessWidget {
  const _PageDetailScreen({required this.page});

  final BookPage page;

  Future<void> _editNote(
    BuildContext context,
    LibraryProvider library,
    BookPage current,
  ) async {
    final controller = TextEditingController(text: current.note ?? '');
    final newNote = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final t = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(t.editNoteTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(labelText: t.editNoteField),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(t.save),
            ),
          ],
        );
      },
    );
    if (newNote == null) return;
    final trimmed = newNote.trim();
    await library.updateBookPage(
      current.copyWith(note: trimmed, clearNote: trimmed.isEmpty),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LibraryProvider library,
    BookPage current,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(t.deletePageTitle),
          content: Text(t.deletePageBody),
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
      await library.deleteBookPage(current);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    // Re-read the live copy so an edited note shows immediately instead of
    // the stale snapshot this screen was pushed with; fall back to that
    // snapshot if the page was just deleted out from under it.
    final current = library
        .pagesFor(page.bookId)
        .firstWhere((p) => p.id == page.id, orElse: () => page);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(current.pageLabel ?? t.savedPageFallbackTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            onPressed: () => _editNote(context, library, current),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, library, current),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(child: AppImage(current.imagePath)),
            ),
          ),
          if (current.note != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(current.note!),
              ),
            ),
        ],
      ),
    );
  }
}
