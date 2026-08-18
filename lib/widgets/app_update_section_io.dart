import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_update_info.dart';
import '../services/update_service.dart';

/// Native: the "check for updates / download / install" section that used
/// to live directly in `SettingsScreen`, unchanged — just moved out so its
/// `dart:io`-based [UpdateService] (APK download + install) stays out of
/// the web build, which has no equivalent concept.
class AppUpdateSection extends StatefulWidget {
  const AppUpdateSection({super.key});

  @override
  State<AppUpdateSection> createState() => _AppUpdateSectionState();
}

class _AppUpdateSectionState extends State<AppUpdateSection> {
  final _updateService = UpdateService();

  bool _checkingUpdate = false;
  String? _updateStatus;
  String? _currentVersion;
  AppUpdateInfo? _availableUpdate;
  bool _downloading = false;
  double _downloadProgress = 0;

  Future<void> _checkForUpdate() async {
    setState(() {
      _checkingUpdate = true;
      _updateStatus = null;
      _availableUpdate = null;
    });
    final t = AppLocalizations.of(context);
    try {
      final current = await _updateService.currentVersion();
      final update = await _updateService.checkForUpdate();
      setState(() {
        _currentVersion = current;
        _availableUpdate = update;
        _updateStatus =
            update == null ? t.upToDate(current) : t.updateAvailable(update.version);
      });
    } catch (e) {
      setState(() => _updateStatus = t.couldNotCheckForUpdates('$e'));
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _downloadAndInstall() async {
    final update = _availableUpdate;
    if (update == null) return;
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      final file = await _updateService.download(
        update,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      await _updateService.install(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).updateFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  void dispose() {
    _updateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.appUpdateSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          t.appUpdateSectionBody,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton(
              onPressed: _checkingUpdate ? null : _checkForUpdate,
              child: _checkingUpdate
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.checkForUpdates),
            ),
            if (_availableUpdate != null) ...[
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _downloading ? null : _downloadAndInstall,
                child: Text(
                  _downloading
                      ? t.downloading((_downloadProgress * 100).round().toString())
                      : t.downloadAndInstall,
                ),
              ),
            ],
          ],
        ),
        if (_updateStatus != null) ...[
          const SizedBox(height: 12),
          Text(_updateStatus!),
        ],
        if (_downloading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
          ),
        ],
        if (_availableUpdate?.releaseNotes.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          Text(
            _availableUpdate!.releaseNotes,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_currentVersion != null) ...[
          const SizedBox(height: 12),
          Text(
            t.currentVersion(_currentVersion!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
