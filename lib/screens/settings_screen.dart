import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_update_info.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../state/library_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _visionApiKeyController = TextEditingController();
  final _updateService = UpdateService();
  bool _loading = true;
  bool _visionKeyObscured = true;

  bool _checkingUpdate = false;
  String? _updateStatus;
  String? _currentVersion;
  AppUpdateInfo? _availableUpdate;
  bool _downloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final visionKey = await SettingsService.instance.getCloudVisionApiKey();
    _visionApiKeyController.text = visionKey ?? '';
    setState(() => _loading = false);
  }

  Future<void> _saveVisionApiKey() async {
    await SettingsService.instance
        .setCloudVisionApiKey(_visionApiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saved)),
      );
    }
  }

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
    _visionApiKeyController.dispose();
    _updateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final library = context.watch<LibraryProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  t.languageSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  t.languageSectionBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SegmentedButton<AppLocale>(
                  segments: [
                    for (final locale in AppLocale.values)
                      ButtonSegment(value: locale, label: Text(locale.label(t))),
                  ],
                  selected: {library.appLocale},
                  onSelectionChanged: (selected) =>
                      library.setAppLocale(selected.first),
                ),
                const Divider(height: 40),
                Text(
                  t.ocrSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  t.ocrSectionBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _visionApiKeyController,
                  obscureText: _visionKeyObscured,
                  decoration: InputDecoration(
                    labelText: t.cloudVisionKeyField,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _visionKeyObscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _visionKeyObscured = !_visionKeyObscured,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saveVisionApiKey,
                  child: Text(t.save),
                ),
                const Divider(height: 40),
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
                              ? t.downloading(
                                  (_downloadProgress * 100).round().toString())
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
            ),
    );
  }
}
