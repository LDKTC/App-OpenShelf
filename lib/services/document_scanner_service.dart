import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

/// Launches Google Play services' document scanner UI in place of a plain
/// camera shot: it auto-detects the page edges, corrects perspective, and
/// crops before handing back the result, so cover/spine/back photos come
/// out flat and tightly cropped without any manual editing.
///
/// Requires Google Play services on-device; the scanner UI itself asks for
/// the camera permission it needs, so no separate `permission_handler`
/// request is required here.
class DocumentScannerService {
  /// Runs the scan flow for a single page and returns the resulting
  /// image's local file path, or null if the user backed out without
  /// completing a scan.
  Future<String?> scanSinglePage() async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.filter,
        pageLimit: 1,
        isGalleryImport: false,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      final images = result.images;
      return (images == null || images.isEmpty) ? null : images.first;
    } finally {
      await scanner.close();
    }
  }
}
