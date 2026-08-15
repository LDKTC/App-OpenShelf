import 'dart:io';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/cover_preset.dart';
import '../services/image_storage_service.dart';
import '../services/settings_service.dart';

/// One book on the visual shelf: its active preset's front-cover or spine
/// image (depending on [mode]), or — when it has no preset with that image
/// yet — a text "info" tile standing in for the missing artwork.
class BookShelfTile extends StatelessWidget {
  const BookShelfTile({
    super.key,
    required this.book,
    required this.activePreset,
    required this.mode,
    required this.onTap,
  });

  final Book book;
  final BookCoverPreset? activePreset;
  final ShelfDisplayMode mode;
  final VoidCallback onTap;

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
        borderRadius: BorderRadius.circular(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox.expand(
            child: path == null
                ? _InfoFallback(book: book, mode: mode)
                : _PresetImage(path: path, book: book, mode: mode),
          ),
        ),
      ),
    );
  }
}

class _PresetImage extends StatelessWidget {
  const _PresetImage({required this.path, required this.book, required this.mode});

  final String path;
  final Book book;
  final ShelfDisplayMode mode;

  @override
  Widget build(BuildContext context) {
    final fallback = _InfoFallback(book: book, mode: mode);
    if (isRemoteImagePath(path)) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
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
