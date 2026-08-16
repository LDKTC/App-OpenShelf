import 'dart:io';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/stamp.dart';
import '../services/image_storage_service.dart';
import 'status_chip.dart';

class BookListTile extends StatelessWidget {
  const BookListTile({
    super.key,
    required this.book,
    this.coverImagePath,
    required this.currentStatus,
    required this.onTap,
    this.onLongPress,
  });

  final Book book;

  /// The book's scanned front-cover photo (its active preset's
  /// `frontImagePath`), preferred over [Book.thumbnailUrl] when present —
  /// the user's own scan of the physical book beats the generic API cover.
  final String? coverImagePath;
  final StampType? currentStatus;
  final VoidCallback onTap;

  /// Long-pressing shows a quick preview sheet instead of navigating in.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final path = coverImagePath ?? book.thumbnailUrl;
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.menu_book_outlined),
    );

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: SizedBox(
        width: 44,
        height: 64,
        child: path == null
            ? placeholder
            : (isRemoteImagePath(path)
                ? Image.network(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => placeholder,
                  )
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => placeholder,
                  )),
      ),
      title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(book.authorsDisplay, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: StatusChip(currentType: currentStatus),
    );
  }
}
