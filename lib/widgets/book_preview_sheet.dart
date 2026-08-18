import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/stamp.dart';
import 'app_image.dart';
import 'status_chip.dart';

/// Shows a quick "hold to preview" bottom sheet for [book] — its cover plus
/// the key facts (series/volume, genre, language, authors, reading status)
/// without leaving the current list/shelf view. Long-pressing a book tile
/// opens this instead of navigating straight to the book's detail screen;
/// tapping "View details" runs [onOpenDetails] to do that navigation.
Future<void> showBookPreview(
  BuildContext context, {
  required Book book,
  String? coverImagePath,
  StampType? currentStatus,
  required VoidCallback onOpenDetails,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _BookPreviewSheet(
      book: book,
      coverImagePath: coverImagePath,
      currentStatus: currentStatus,
      onOpenDetails: onOpenDetails,
    ),
  );
}

class _BookPreviewSheet extends StatelessWidget {
  const _BookPreviewSheet({
    required this.book,
    required this.coverImagePath,
    required this.currentStatus,
    required this.onOpenDetails,
  });

  final Book book;
  final String? coverImagePath;
  final StampType? currentStatus;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final path = coverImagePath ?? book.thumbnailUrl;
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.menu_book_outlined, size: 28),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 72,
                    height: 104,
                    child: path == null
                        ? placeholder
                        : AppImage(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                placeholder,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (book.series != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          book.seriesVolumeDisplay != null
                              ? t.seriesWithVolume(
                                  book.series!, book.seriesVolumeDisplay!)
                              : book.series!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        book.authorsDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      StatusChip(currentType: currentStatus),
                    ],
                  ),
                ),
              ],
            ),
            if (book.genre != null || book.language != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (book.genre != null)
                    Chip(
                      avatar: const Icon(Icons.category_outlined, size: 16),
                      label: Text(book.genre!),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (book.language != null)
                    Chip(
                      avatar: const Icon(Icons.translate, size: 16),
                      label: Text(book.language!),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).pop();
                onOpenDetails();
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(t.viewDetailsLabel),
            ),
          ],
        ),
      ),
    );
  }
}
