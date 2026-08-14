import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/read_status.dart';
import '../state/library_provider.dart';
import 'book_edit_screen.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final book = library.getById(bookId);

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This book was removed.')),
      );
    }

    final categoryIds = library.categoryIdsFor(bookId).toSet();
    final categories =
        library.categories.where((c) => categoryIds.contains(c.id)).toList();

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
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove book?'),
                  content: Text('Delete "${book.title}" from your library?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
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
                child: book.thumbnailUrl == null
                    ? Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.menu_book_outlined, size: 32),
                      )
                    : Image.network(book.thumbnailUrl!, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(book.authorsDisplay, style: Theme.of(context).textTheme.bodyMedium),
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
                      Text('ISBN ${book.isbn13}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Reading status', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ReadStatus>(
            segments: [
              for (final status in ReadStatus.values)
                ButtonSegment(value: status, label: Text(status.label)),
            ],
            selected: {book.status},
            onSelectionChanged: (s) => library.setStatus(book, s.first),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Categories', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [for (final c in categories) Chip(label: Text(c.name))],
            ),
          ],
          if (book.description != null) ...[
            const SizedBox(height: 20),
            Text('Description', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(book.description!),
          ],
          if (book.notes != null) ...[
            const SizedBox(height: 20),
            Text('My notes', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(book.notes!),
          ],
          if (book.source != null) ...[
            const SizedBox(height: 20),
            Text(
              'Source: ${book.source}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
