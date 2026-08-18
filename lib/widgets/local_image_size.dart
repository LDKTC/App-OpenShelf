// Future<Size?> resolveLocalImageSize(String path) -- a local image's
// intrinsic pixel size, resolved from a real file natively or from
// database-stored bytes on web. See AppImage for the equivalent widget.
export 'local_image_size_web.dart'
    if (dart.library.io) 'local_image_size_io.dart';
