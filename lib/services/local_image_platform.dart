/// Picks the real (native) or browser-backed (web) implementation of
/// [ImageStorageService]'s save/delete primitives at compile time, so the
/// `dart:io`-only native implementation is never pulled into a web build.
export 'local_image_platform_web.dart'
    if (dart.library.io) 'local_image_platform_io.dart';
