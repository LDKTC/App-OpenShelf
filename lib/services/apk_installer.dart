import 'package:flutter/services.dart';

/// Thin wrapper over the native `quetzalib/apk_installer` platform channel,
/// which hands a downloaded APK to Android's package installer via a
/// FileProvider content URI (Android refuses to install from a plain
/// file:// path).
class ApkInstaller {
  static const _channel = MethodChannel('quetzalib/apk_installer');

  static Future<void> install(String apkPath) {
    return _channel.invokeMethod('installApk', {'path': apkPath});
  }
}
