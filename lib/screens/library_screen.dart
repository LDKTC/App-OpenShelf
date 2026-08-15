import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../state/library_provider.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/shelf_grid_view.dart';
import 'book_detail_screen.dart';
import 'book_edit_screen.dart';
import 'isbn_entry_screen.dart';
import 'scan_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  bool _shelfView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBook(BuildContext context, int bookId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final books = library.filteredBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        actions: [
          if (_shelfView)
            IconButton(
              icon: Icon(
                library.shelfDisplayMode == ShelfDisplayMode.spine
                    ? Icons.menu_book_outlined
                    : Icons.view_agenda_outlined,
              ),
              tooltip: library.shelfDisplayMode == ShelfDisplayMode.spine
                  ? 'Showing spines · tap for covers'
                  : 'Showing covers · tap for spines',
              onPressed: () => library.setShelfDisplayMode(
                library.shelfDisplayMode == ShelfDisplayMode.spine
                    ? ShelfDisplayMode.cover
                    : ShelfDisplayMode.spine,
              ),
            ),
          IconButton(
            icon: Icon(_shelfView ? Icons.view_list_outlined : Icons.grid_view_outlined),
            tooltip: _shelfView ? 'List view' : 'Shelf view',
            onPressed: () => setState(() => _shelfView = !_shelfView),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search title, author, ISBN',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan to search',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ScanScreen(mode: ScanMode.search),
                    ),
                  ),
                ),
                isDense: true,
              ),
              onChanged: library.setSearchQuery,
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const _StatusFilterChip(filter: null, label: 'All'),
                for (final filter in LibraryStatusFilter.values)
                  _StatusFilterChip(filter: filter, label: filter.label),
                if (library.categories.isNotEmpty) ...[
                  const VerticalDivider(width: 16),
                  for (final category in library.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.name),
                        selected: library.categoryFilterId == category.id,
                        onSelected: (selected) => library.setCategoryFilter(
                          selected ? category.id : null,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: library.loading
                ? const Center(child: CircularProgressIndicator())
                : books.isEmpty
                    ? const _EmptyState()
                    : (_shelfView
                        ? ShelfGridView(
                            onTapBook: (bookId) => _openBook(context, bookId),
                          )
                        : ListView.separated(
                            itemCount: books.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return BookListTile(
                                book: book,
                                currentStatus: library.currentStampFor(book.id!)?.type,
                                onTap: () => _openBook(context, book.id!),
                              );
                            },
                          )),
          ),
        ],
      ),
      floatingActionButton: _AddBookMenu(),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({required this.filter, required this.label});

  final LibraryStatusFilter? filter;
  final String label;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: library.statusFilter == filter,
        onSelected: (_) => library.setStatusFilter(filter),
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
              'No books yet. Scan a barcode or add one manually to get started.',
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
          child: const Text('Scan ISBN barcode'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.pin_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IsbnEntryScreen()),
          ),
          child: const Text('Enter ISBN number'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookEditScreen()),
          ),
          child: const Text('Add manually'),
        ),
      ],
    );
  }
}
