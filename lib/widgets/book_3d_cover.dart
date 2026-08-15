import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/cover_preset.dart';
import '../services/image_storage_service.dart';

/// Pushes a full-screen 3D mockup of [preset]'s front/spine/back photos.
void showBook3DPreview(BuildContext context, BookCoverPreset preset) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _Book3DPreviewScreen(preset: preset),
      fullscreenDialog: true,
    ),
  );
}

class _Book3DPreviewScreen extends StatelessWidget {
  const _Book3DPreviewScreen({required this.preset});

  final BookCoverPreset preset;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(t.book3DPreviewTitle),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Book3DCover(preset: preset),
            if (preset.backImagePath != null) ...[
              const SizedBox(height: 24),
              Text(
                t.book3DFlipHint,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A pseudo-3D "book" render assembled from a cover preset's scanned faces.
/// Tap to flip between the front+spine view and the back+spine view — a
/// physical book only has one spine face to scan, so that same spine photo
/// is reused on both the left edge (front view) and the right edge (back
/// view) rather than leaving the other edge blank.
class Book3DCover extends StatefulWidget {
  const Book3DCover({super.key, required this.preset});

  final BookCoverPreset preset;

  @override
  State<Book3DCover> createState() => _Book3DCoverState();
}

class _Book3DCoverState extends State<Book3DCover> {
  bool _showBack = false;

  bool get _canFlip => widget.preset.backImagePath != null;

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final showBack = _showBack && _canFlip;
    final mainPath = showBack ? preset.backImagePath : preset.frontImagePath;

    return GestureDetector(
      onTap: _canFlip ? () => setState(() => _showBack = !_showBack) : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _BookSpread(
          key: ValueKey(showBack),
          mainPath: mainPath,
          spinePath: preset.spineImagePath,
          flipped: showBack,
        ),
      ),
    );
  }
}

class _BookSpread extends StatelessWidget {
  const _BookSpread({
    super.key,
    required this.mainPath,
    required this.spinePath,
    required this.flipped,
  });

  final String? mainPath;
  final String? spinePath;
  final bool flipped;

  static const _coverWidth = 170.0;
  static const _coverHeight = 240.0;
  static const _spineWidth = 26.0;
  static const _tilt = 0.5; // radians

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.menu_book_outlined, size: 32),
    );

    Widget faceImage(String? path) {
      if (path == null) return placeholder;
      return isRemoteImagePath(path)
          ? Image.network(
              path,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            );
    }

    final spine = Container(
      width: _spineWidth,
      height: _coverHeight,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(-2, 2)),
        ],
      ),
      child: faceImage(spinePath),
    );

    final main = Transform(
      alignment: flipped ? Alignment.centerRight : Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0016)
        ..rotateY(flipped ? _tilt : -_tilt),
      child: Container(
        width: _coverWidth,
        height: _coverHeight,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(4, 4)),
          ],
        ),
        child: faceImage(mainPath),
      ),
    );

    return SizedBox(
      width: _coverWidth + _spineWidth,
      height: _coverHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: flipped ? [main, spine] : [spine, main],
      ),
    );
  }
}
