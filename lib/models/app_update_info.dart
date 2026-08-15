/// A newer OpenShelf build found on GitHub Releases.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.apkSizeBytes,
    required this.releaseNotes,
    required this.releaseUrl,
  });

  final String version;
  final String downloadUrl;
  final int apkSizeBytes;
  final String releaseNotes;
  final String releaseUrl;
}
