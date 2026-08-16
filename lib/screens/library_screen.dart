import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../services/settings_service.dart';
import '../state/library_provider.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/book_preview_sheet.dart';
import '../widgets/shelf_grid_view.dart';
import 'book_detail_screen.dart';
import 'book_edit_screen.dart';
import 'isbn_entry_screen.dart';
import 'scan_cover_first_screen.dart';
import 'scan_screen.dart';

extension on LibraryViewMode {
  IconData get icon => switch (this) {
        LibraryViewMode.list => Icons.view_list_outlined,
        LibraryViewMode.shelfCover => Icons.grid_view_outlined,
        LibraryViewMode.shelfSpine => Icons.menu_book_outlined,
      };
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _viewModeButtonKey = GlobalKey();
  bool _searchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openBook(BuildContext context, int bookId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
    );
  }

  void _toggleSearch(LibraryProvider library) {
    setState(() => _searchExpanded = !_searchExpanded);
    if (_searchExpanded) {
      _searchFocusNode.requestFocus();
    } else {
      _searchController.clear();
      library.setSearchQuery('');
    }
  }

  Future<void> _pickViewMode(LibraryProvider library) async {
    final button =
        _viewModeButtonKey.currentContext!.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
            button.size.bottomLeft(Offset.zero), ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final t = AppLocalizations.of(context);
    final selected = await showMenu<LibraryViewMode>(
      context: context,
      position: position,
      items: [
        for (final mode in LibraryViewMode.values)
          PopupMenuItem(
            value: mode,
            child: Row(
              children: [
                Icon(mode.icon, size: 20),
                const SizedBox(width: 12),
                Text(mode.label(t)),
                if (mode == library.viewMode) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
      ],
    );
    if (selected != null) {
      library.setViewMode(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final books = library.filteredBooks;
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.myLibrary),
        actions: [
          IconButton(
            icon: Icon(_searchExpanded ? Icons.search_off : Icons.search),
            tooltip: _searchExpanded ? t.closeSearch : t.openSearch,
            onPressed: () => _toggleSearch(library),
          ),
          IconButton(
            key: _viewModeButtonKey,
            icon: Icon(library.viewMode.icon),
            tooltip: t.switchToViewMode(library.viewMode.next.label(t)),
            onPressed: library.cycleViewMode,
            onLongPress: () => _pickViewMode(library),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _searchExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: t.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: t.scanToSearch,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ScanScreen(mode: ScanMode.search),
                            ),
                          ),
                        ),
                        isDense: true,
                      ),
                      onChanged: library.setSearchQuery,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SelectButton<LibraryStatusFilter?>(
                    icon: Icons.filter_list,
                    tooltip: t.filterStatusLabel,
                    value: library.statusFilter,
                    onChanged: library.setStatusFilter,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('${t.filterAll} (${library.totalBookCount})'),
                      ),
                      for (final filter in LibraryStatusFilter.values)
                        DropdownMenuItem(
                          value: filter,
                          child: Text(
                            '${filter.label(t)} (${library.statusCounts[filter]})',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  _SelectButton<LibrarySortField>(
                    icon: Icons.sort,
                    tooltip: t.sortByLabel,
                    value: library.sortField,
                    onChanged: (field) {
                      if (field != null) library.setSortField(field);
                    },
                    items: [
                      for (final field in LibrarySortField.values)
                        DropdownMenuItem(value: field, child: Text(field.label(t))),
                    ],
                  ),
                  if (library.categories.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _SelectButton<int?>(
                      icon: Icons.category_outlined,
                      tooltip: t.filterCategoryLabel,
                      value: library.categoryFilterId,
                      onChanged: library.setCategoryFilter,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('${t.filterAll} (${library.totalBookCount})'),
                        ),
                        for (final category in library.categories)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(
                              '${category.name} (${library.categoryCounts[category.id] ?? 0})',
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (!library.loading && books.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.bookCountLabel(books.length.toString()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          Expanded(
            child: library.loading
                ? const Center(child: CircularProgressIndicator())
                : books.isEmpty
                    ? const _EmptyState()
                    : (library.viewMode == LibraryViewMode.list
                        ? _BookListView(
                            books: books,
                            sortField: library.sortField,
                            library: library,
                            onTapBook: (bookId) => _openBook(context, bookId),
                          )
                        : ShelfGridView(
                            onTapBook: (bookId) => _openBook(context, bookId),
                          )),
          ),
        ],
      ),
      floatingActionButton: _AddBookMenu(),
    );
  }
}

/// A bordered, pill-shaped dropdown ("select") button: an icon plus the
/// current selection's label, tapping it opens the options menu — used for
/// both the status filter and the sort-field picker so the library screen
/// only needs one row for both instead of a full chip-per-option list.
class _SelectButton<T> extends StatelessWidget {
  const _SelectButton({
    required this.icon,
    required this.tooltip,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String tooltip;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, size: 18),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the sorted/grouped library list: either a book, a section
/// header (the date or series it was grouped under), or a plain divider
/// between two consecutive books in the same section.
sealed class _LibraryRow {}

class _HeaderRow extends _LibraryRow {
  _HeaderRow(this.label);
  final String label;
}

class _BookRow extends _LibraryRow {
  _BookRow(this.book);
  final Book book;
}

class _DividerRow extends _LibraryRow {}

/// The section header a book falls under for the current [sortField], or
/// null when that field isn't grouped (title/author/publisher/ISBN stay a
/// plain flat list, same as before sorting existed).
String? _groupHeaderFor(Book book, LibrarySortField sortField, AppLocalizations t) {
  switch (sortField) {
    case LibrarySortField.dateAdded:
      final d = book.dateAdded;
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return '${d.year}-$mm-$dd';
    case LibrarySortField.series:
      final series = book.series;
      return (series == null || series.isEmpty) ? t.noSeriesGroupLabel : series;
    case LibrarySortField.languageGenre:
      final parts = [
        if (book.language != null && book.language!.isNotEmpty) book.language!,
        if (book.genre != null && book.genre!.isNotEmpty) book.genre!,
      ];
      return parts.isEmpty ? t.noLanguageGenreGroupLabel : parts.join(' · ');
    case LibrarySortField.title:
    case LibrarySortField.author:
    case LibrarySortField.publisher:
    case LibrarySortField.isbn:
      return null;
  }
}

/// Turns the already-sorted [books] into header/book/divider rows: a
/// header is inserted whenever the group key changes, a divider between
/// two consecutive books in the same (or no) group — mirroring what
/// `ListView.separated`'s plain `Divider` used to do before grouping.
List<_LibraryRow> _buildLibraryRows(
  List<Book> books,
  LibrarySortField sortField,
  AppLocalizations t,
) {
  final rows = <_LibraryRow>[];
  String? lastHeader;
  for (final book in books) {
    final header = _groupHeaderFor(book, sortField, t);
    if (header != null && header != lastHeader) {
      rows.add(_HeaderRow(header));
    } else if (rows.isNotEmpty && rows.last is _BookRow) {
      rows.add(_DividerRow());
    }
    rows.add(_BookRow(book));
    lastHeader = header;
  }
  return rows;
}

class _BookListView extends StatelessWidget {
  const _BookListView({
    required this.books,
    required this.sortField,
    required this.library,
    required this.onTapBook,
  });

  final List<Book> books;
  final LibrarySortField sortField;
  final LibraryProvider library;
  final void Function(int bookId) onTapBook;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rows = _buildLibraryRows(books, sortField, t);
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return switch (row) {
          _HeaderRow(:final label) => _SectionHeader(label: label),
          _DividerRow() => const Divider(height: 1),
          _BookRow(:final book) => BookListTile(
              book: book,
              coverImagePath:
                  library.activeCoverPresetFor(book.id!)?.frontImagePath,
              currentStatus: library.currentStampFor(book.id!)?.type,
              onTap: () => onTapBook(book.id!),
              onLongPress: () => showBookPreview(
                context,
                book: book,
                coverImagePath:
                    library.activeCoverPresetFor(book.id!)?.frontImagePath,
                currentStatus: library.currentStampFor(book.id!)?.type,
                onOpenDetails: () => onTapBook(book.id!),
              ),
            ),
        };
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).emptyLibrary,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBookMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return MenuAnchor(
      builder: (context, controller, child) {
        return FloatingActionButton(
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          child: const Icon(Icons.add),
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.qr_code_scanner),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          ),
          child: Text(t.scanIsbnBarcode),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.pin_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IsbnEntryScreen()),
          ),
          child: Text(t.enterIsbnNumber),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.add_a_photo_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScanCoverFirstScreen()),
          ),
          child: Text(t.scanCoverFirstLabel),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookEditScreen()),
          ),
          child: Text(t.addManually),
        ),
      ],
    );
  }
}
