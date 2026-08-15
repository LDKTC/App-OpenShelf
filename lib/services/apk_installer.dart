import 'dart:async';

import 'package:flutter/services.dart';

/// How an update install attempt concluded.
enum InstallOutcome {
  /// The APK installed successfully.
  success,

  /// Android refused to install because the update is signed with a
  /// different certificate than the app already on the device.
  conflict,

  /// Any other install failure (cancelled by the user, corrupt APK, etc).
  failure,
}

class InstallResult {
  const InstallResult(this.outcome, this.message);

  final InstallOutcome outcome;
  final String? message;
}

/// Thin wrapper over the native `quetzalib/apk_installer` platform channel,
/// which hands a downloaded APK to Android's `PackageInstaller` and reports
/// back the final install outcome once the user completes (or the OS
/// rejects) the install flow.
class ApkInstaller {
  static const _channel = MethodChannel('quetzalib/apk_installer');
  static final _results = StreamController<InstallResult>.broadcast();
  static bool _listening = false;

  static void _ensureListening() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'installResult') return;
      final args = (call.arguments as Map).cast<String, dynamic>();
      final outcome = switch (args['status']) {
        'success' => InstallOutcome.success,
        'conflict' => InstallOutcome.conflict,
        _ => InstallOutcome.failure,
      };
      _results.add(InstallResult(outcome, args['message'] as String?));
    });
  }

  /// Starts installing [apkPath] and returns the final [InstallResult] once
  /// the system installer reports one.
  static Future<InstallResult> install(String apkPath) async {
    _ensureListening();
    final result = _results.stream.first;
    await _channel.invokeMethod('installApk', {'path': apkPath});
    return result;
  }
}
