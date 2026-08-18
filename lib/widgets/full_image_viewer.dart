import 'package:flutter/material.dart';

import 'app_image.dart';

/// Pushes a full-screen, pinch-to-zoom preview of a single local or remote
/// image. Used wherever a saved photo (a cover slot, a preset thumbnail)
/// should show itself immediately on tap instead of routing back through
/// whatever screen picked/saved it.
void showFullImagePreview(BuildContext context, String path) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _FullImageViewer(path: path),
      fullscreenDialog: true,
    ),
  );
}

class _FullImageViewer extends StatelessWidget {
  const _FullImageViewer({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final image = AppImage(path, fit: BoxFit.contain);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: image,
        ),
      ),
    );
  }
}
