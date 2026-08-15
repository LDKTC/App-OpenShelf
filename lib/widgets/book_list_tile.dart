import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/stamp.dart';
import 'status_chip.dart';

class BookListTile extends StatelessWidget {
  const BookListTile({
    super.key,
    required this.book,
    required this.currentStatus,
    required this.onTap,
  });

  final Book book;
  final StampType? currentStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 44,
        height: 64,
        child: book.thumbnailUrl == null
            ? Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.menu_book_outlined),
              )
            : Image.network(
                book.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.menu_book_outlined),
                ),
              ),
      ),
      title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(book.authorsDisplay, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: StatusChip(currentType: currentStatus),
    );
  }
}
