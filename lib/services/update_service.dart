import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_update_info.dart';
import 'apk_installer.dart';

/// Checks GitHub Releases for a newer QuetzaLib build and, when the user
/// opts in, downloads the APK and hands it to the system installer — the
/// standard way to update a sideloaded Android app that isn't distributed
/// through the Play Store.
class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static const _releasesUrl =
      'https://api.github.com/repos/LDKTC/App-QuetzaLib/releases/latest';

  final http.Client _client;

  /// The currently installed app version, e.g. "1.0.1".
  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Fetches the latest GitHub release and returns its details if it's
  /// newer than the installed version and has an APK asset attached, or
  /// null if the app is already up to date.
  Future<AppUpdateInfo?> checkForUpdate() async {
    final current = await currentVersion();

    final response = await _client.get(
      Uri.parse(_releasesUrl),
      headers: const {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('GitHub returned HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = body['tag_name'] as String?;
    if (tagName == null) return null;
    final latest = tagName.startsWith('v') ? tagName.substring(1) : tagName;

    if (!_isNewer(latest, current)) return null;

    Map<String, dynamic>? apkAsset;
    for (final asset in (body['assets'] as List<dynamic>? ?? [])) {
      final map = asset as Map<String, dynamic>;
      if ((map['name'] as String? ?? '').endsWith('.apk')) {
        apkAsset = map;
        break;
      }
    }
    final downloadUrl = apkAsset?['browser_download_url'] as String?;
    if (downloadUrl == null) return null;

    return AppUpdateInfo(
      version: latest,
      downloadUrl: downloadUrl,
      apkSizeBytes: apkAsset?['size'] as int? ?? 0,
      releaseNotes: (body['body'] as String? ?? '').trim(),
      releaseUrl: body['html_url'] as String? ?? '',
    );
  }

  /// Downloads [update]'s APK to a private cache folder, reporting progress
  /// in `[0, 1]` via [onProgress], and returns the local file.
  Future<File> download(
    AppUpdateInfo update, {
    void Function(double progress)? onProgress,
  }) async {
    final response = await _client.send(
      http.Request('GET', Uri.parse(update.downloadUrl)),
    );
    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    final total = response.contentLength ?? update.apkSizeBytes;
    final dir = Directory('${(await getTemporaryDirectory()).path}/updates');
    await dir.create(recursive: true);
    final file = File('${dir.path}/quetzalib-${update.version}.apk');

    var received = 0;
    final sink = file.openWrite();
    try {
      await response.stream.map((chunk) {
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
        return chunk;
      }).pipe(sink);
    } finally {
      await sink.close();
    }
    return file;
  }

  /// Requests the "install unknown apps" permission if needed, then hands
  /// [apk] to the system package installer.
  Future<void> install(File apk) async {
    var status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      status = await Permission.requestInstallPackages.request();
    }
    if (!status.isGranted) {
      throw Exception(
        'QuetzaLib needs permission to install updates. Allow '
        '"Install unknown apps" for QuetzaLib in system settings, then '
        'try again.',
      );
    }
    await ApkInstaller.install(apk.path);
  }

  /// True if dotted version [a] is greater than [b]. A trailing `-suffix`
  /// (e.g. "1.2.0-prototype") is ignored for comparison.
  bool _isNewer(String a, String b) {
    List<int> parts(String v) => v
        .split('-')
        .first
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();

    final pa = parts(a);
    final pb = parts(b);
    for (var i = 0; i < pa.length || i < pb.length; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va > vb;
    }
    return false;
  }

  void dispose() => _client.close();
}
