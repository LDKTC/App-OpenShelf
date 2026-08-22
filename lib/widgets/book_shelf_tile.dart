import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/cover_preset.dart';
import '../models/stamp.dart';
import '../services/image_storage_service.dart';
import '../services/settings_service.dart';
import 'app_image.dart';
import 'local_image_size.dart';
import 'status_chip.dart';

/// One book on the visual shelf: its active preset's front-cover or spine
/// image (depending on [mode]), or — when it has no preset with that image
/// yet — a text "info" tile standing in for the missing artwork. Its
/// current reading status, when it has one, overlays as a small badge —
/// the shelf views have no room for the list view's full [StatusChip], so
/// this is their equivalent.
class BookShelfTile extends StatelessWidget {
  const BookShelfTile({
    super.key,
    required this.book,
    required this.activePreset,
    this.currentStatus,
    required this.mode,
    required this.onTap,
    this.onLongPress,
  });

  final Book book;
  final BookCoverPreset? activePreset;
  final StampType? currentStatus;
  final ShelfDisplayMode mode;
  final VoidCallback onTap;

  /// Long-pressing shows a quick preview sheet instead of navigating in.
  final VoidCallback? onLongPress;

  String? get _imagePath => mode == ShelfDisplayMode.spine
      ? activePreset?.spineImagePath
      : activePreset?.frontImagePath;

  @override
  Widget build(BuildContext context) {
    final path = _imagePath;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              SizedBox.expand(
                child: path == null
                    ? _InfoFallback(book: book, mode: mode)
                    : _PresetImage(path: path, book: book, mode: mode),
              ),
              if (currentStatus != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _StatusBadge(type: currentStatus!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small circular badge showing a book's current reading-status icon,
/// overlaid on its cover/spine artwork in the shelf views.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.type});

  final StampType type;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) =
        stampVisuals(AppLocalizations.of(context), type);
    return Tooltip(
      message: label,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.55),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}

class _PresetImage extends StatelessWidget {
  const _PresetImage({
    required this.path,
    required this.book,
    required this.mode,
    this.fit = BoxFit.cover,
  });

  final String path;
  final Book book;
  final ShelfDisplayMode mode;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = _InfoFallback(book: book, mode: mode);
    return AppImage(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

/// The spine shelf's "many books in a row" layout: each book's spine
/// renders at a shared height but at its own natural width (derived from
/// the image's actual pixel aspect ratio), so a thick book's spine is
/// visibly wider than a thin one instead of every spine being squashed
/// into the same fixed-ratio cell.
class SpineShelfView extends StatelessWidget {
  const SpineShelfView({
    super.key,
    required this.books,
    required this.presetFor,
    this.statusFor,
    required this.onTapBook,
    this.onLongPressBook,
  });

  final List<Book> books;
  final BookCoverPreset? Function(int bookId) presetFor;
  final StampType? Function(int bookId)? statusFor;
  final void Function(int bookId) onTapBook;

  /// Long-pressing shows a quick preview sheet instead of navigating in.
  final void Function(int bookId)? onLongPressBook;

  static const double rowHeight = 180;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 6,
        runSpacing: 12,
        children: [
          for (final book in books)
            _SpineTile(
              key: ValueKey(book.id),
              book: book,
              path: presetFor(book.id!)?.spineImagePath,
              currentStatus: statusFor?.call(book.id!),
              height: rowHeight,
              onTap: () => onTapBook(book.id!),
              onLongPress: onLongPressBook == null
                  ? null
                  : () => onLongPressBook!(book.id!),
            ),
        ],
      ),
    );
  }
}

/// The expanded form of a spine section: the same wrapping layout
/// [SpineShelfView] uses for the flat (ungrouped) spine shelf, but scoped to
/// one section's books and without its own scroll view — it's embedded
/// inside the shelf's outer scroll view.
class SpineShelfGrid extends StatelessWidget {
  const SpineShelfGrid({
    super.key,
    required this.books,
    required this.presetFor,
    this.statusFor,
    required this.onTapBook,
    this.onLongPressBook,
  });

  final List<Book> books;
  final BookCoverPreset? Function(int bookId) presetFor;
  final StampType? Function(int bookId)? statusFor;
  final void Function(int bookId) onTapBook;
  final void Function(int bookId)? onLongPressBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 6,
        runSpacing: 12,
        children: [
          for (final book in books)
            _SpineTile(
              key: ValueKey(book.id),
              book: book,
              path: presetFor(book.id!)?.spineImagePath,
              currentStatus: statusFor?.call(book.id!),
              height: SpineShelfView.rowHeight,
              onTap: () => onTapBook(book.id!),
              onLongPress: onLongPressBook == null
                  ? null
                  : () => onLongPressBook!(book.id!),
            ),
        ],
      ),
    );
  }
}

/// One section of the sectioned spine shelf: a single horizontally
/// scrolling row of spines, used instead of [SpineShelfView]'s wrapping
/// layout when the shelf is grouped (e.g. one row per series) — a section
/// with more books than fit the screen width slides sideways rather than
/// spilling onto a second row.
class SpineShelfRow extends StatelessWidget {
  const SpineShelfRow({
    super.key,
    required this.books,
    required this.presetFor,
    this.statusFor,
    required this.onTapBook,
    this.onLongPressBook,
  });

  final List<Book> books;
  final BookCoverPreset? Function(int bookId) presetFor;
  final StampType? Function(int bookId)? statusFor;
  final void Function(int bookId) onTapBook;
  final void Function(int bookId)? onLongPressBook;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SpineShelfView.rowHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final book = books[index];
          return _SpineTile(
            key: ValueKey(book.id),
            book: book,
            path: presetFor(book.id!)?.spineImagePath,
            currentStatus: statusFor?.call(book.id!),
            height: SpineShelfView.rowHeight,
            onTap: () => onTapBook(book.id!),
            onLongPress: onLongPressBook == null
                ? null
                : () => onLongPressBook!(book.id!),
          );
        },
      ),
    );
  }
}

/// One section of the sectioned cover shelf: a single horizontally
/// scrolling row of covers, sized via the same width/height ratio the flat
/// cover grid uses — the cover-mode counterpart of [SpineShelfRow].
class CoverShelfRow extends StatelessWidget {
  const CoverShelfRow({
    super.key,
    required this.books,
    required this.activePresetFor,
    this.statusFor,
    required this.onTapBook,
    this.onLongPressBook,
  });

  final List<Book> books;
  final BookCoverPreset? Function(int bookId) activePresetFor;
  final StampType? Function(int bookId)? statusFor;
  final void Function(int bookId) onTapBook;
  final void Function(int bookId)? onLongPressBook;

  static const double rowHeight = 190;
  static const double _aspectRatio = 0.68; // width / height

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: rowHeight * _aspectRatio,
            child: BookShelfTile(
              book: book,
              activePreset: activePresetFor(book.id!),
              currentStatus: statusFor?.call(book.id!),
              mode: ShelfDisplayMode.cover,
              onTap: () => onTapBook(book.id!),
              onLongPress: onLongPressBook == null
                  ? null
                  : () => onLongPressBook!(book.id!),
            ),
          );
        },
      ),
    );
  }
}

/// The expanded form of a cover section: the same 3-column wrapping grid
/// the flat (ungrouped) cover shelf uses, but scoped to one section's books
/// and non-scrolling — it's embedded inside the shelf's outer scroll view.
class CoverShelfGrid extends StatelessWidget {
  const CoverShelfGrid({
    super.key,
    required this.books,
    required this.activePresetFor,
    this.statusFor,
    required this.onTapBook,
    this.onLongPressBook,
  });

  final List<Book> books;
  final BookCoverPreset? Function(int bookId) activePresetFor;
  final StampType? Function(int bookId)? statusFor;
  final void Function(int bookId) onTapBook;
  final void Function(int bookId)? onLongPressBook;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
          activePreset: activePresetFor(book.id!),
          currentStatus: statusFor?.call(book.id!),
          mode: ShelfDisplayMode.cover,
          onTap: () => onTapBook(book.id!),
          onLongPress:
              onLongPressBook == null ? null : () => onLongPressBook!(book.id!),
        );
      },
    );
  }
}

class _SpineTile extends StatefulWidget {
  const _SpineTile({
    super.key,
    required this.book,
    required this.path,
    this.currentStatus,
    required this.height,
    required this.onTap,
    this.onLongPress,
  });

  final Book book;
  final String? path;
  final StampType? currentStatus;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_SpineTile> createState() => _SpineTileState();
}

class _SpineTileState extends State<_SpineTile> {
  static const _fallbackAspect = 0.22;

  Size? _size;

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  @override
  void didUpdateWidget(covariant _SpineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _loadSize();
  }

  void _loadSize() {
    final path = widget.path;
    if (path == null) {
      setState(() => _size = null);
      return;
    }
    resolveLocalImageSize(path).then((size) {
      if (mounted) setState(() => _size = size);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    final aspect =
        (size != null && size.height > 0) ? size.width / size.height : _fallbackAspect;
    final width = (widget.height * aspect).clamp(28.0, widget.height * 0.6);

    return SizedBox(
      width: width,
      height: widget.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                SizedBox.expand(
                  child: widget.path == null
                      ? _InfoFallback(
                          book: widget.book, mode: ShelfDisplayMode.spine)
                      : _PresetImage(
                          path: widget.path!,
                          book: widget.book,
                          mode: ShelfDisplayMode.spine,
                          fit: BoxFit.contain,
                        ),
                ),
                if (widget.currentStatus != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: _StatusBadge(type: widget.currentStatus!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _imageSizeCache = <String, Size>{};

/// Resolves the intrinsic pixel size of a local or remote image, caching
/// the result by path/URL so the same spine image is only decoded once per
/// app session. Remote/local resolution mirrors [AppImage]: a network
/// image resolves via [NetworkImage]; a local one via [resolveLocalImageSize]
/// (a real file natively, database-stored bytes on web).
Future<Size?> resolveImageSize(String path) async {
  final cached = _imageSizeCache[path];
  if (cached != null) return cached;

  final size = isRemoteImagePath(path)
      ? await _resolveNetworkImageSize(path)
      : await resolveLocalImageSize(path);
  if (size != null) _imageSizeCache[path] = size;
  return size;
}

Future<Size?> _resolveNetworkImageSize(String path) {
  final provider = NetworkImage(path);
  final completer = Completer<Size?>();
  final stream = provider.resolve(const ImageConfiguration());
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      final size = Size(info.image.width.toDouble(), info.image.height.toDouble());
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(size);
    },
    onError: (error, stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(null);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

class _InfoFallback extends StatelessWidget {
  const _InfoFallback({required this.book, required this.mode});

  final Book book;
  final ShelfDisplayMode mode;

  @override
  Widget build(BuildContext context) {
    final color = _colorForTitle(book.title);
    final isSpine = mode == ShelfDisplayMode.spine;
    return Container(
      color: color,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: isSpine
          ? RotatedBox(
              quarterTurns: 3,
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.title,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  book.authorsDisplay,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
    );
  }
}

/// A deterministic color per title so the same book always gets the same
/// info-tile color, and different books are visually distinguishable.
Color _colorForTitle(String title) {
  const palette = [
    Color(0xFF6750A4),
    Color(0xFF386A20),
    Color(0xFF8B4513),
    Color(0xFF00696D),
    Color(0xFF984061),
    Color(0xFF6B5900),
  ];
  if (title.isEmpty) return palette[0];
  final sum = title.codeUnits.fold<int>(0, (total, c) => total + c);
  return palette[sum % palette.length];
}
