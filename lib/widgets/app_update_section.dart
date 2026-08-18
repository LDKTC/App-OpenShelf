// AppUpdateSection -- the in-app "check for updates" UI on native
// platforms, or nothing on web (see app_update_section_web.dart) -- kept
// out of settings_screen.dart directly so its dart:io-based UpdateService
// (APK download + install) doesn't get pulled into the web build, which
// has no APK-install equivalent.
export 'app_update_section_web.dart'
    if (dart.library.io) 'app_update_section_io.dart';
