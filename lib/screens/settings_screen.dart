import 'package:flutter/material.dart';

import '../models/app_update_info.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';

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
        const SnackBar(content: Text('Saved.')),
      );
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checkingUpdate = true;
      _updateStatus = null;
      _availableUpdate = null;
    });
    try {
      final current = await _updateService.currentVersion();
      final update = await _updateService.checkForUpdate();
      setState(() {
        _currentVersion = current;
        _availableUpdate = update;
        _updateStatus = update == null
            ? "You're up to date (v$current)."
            : 'Update available: v${update.version}';
      });
    } catch (e) {
      setState(() => _updateStatus = 'Could not check for updates: $e');
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
          SnackBar(content: Text('Update failed: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Text scanning (OCR)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The camera-scan buttons next to Title, Authors, '
                  'Illustrators, ISBN, and Publisher in the book editor use '
                  'on-device text recognition by default — free and '
                  'offline, but Latin-script only, so Thai text won\'t be '
                  'read correctly. Enter a Google Cloud Vision API key here '
                  'to use it instead: it reads Thai as well as Latin text, '
                  'at the cost of a network request per scan billed to your '
                  'Cloud account. Leave it blank to keep using on-device '
                  'recognition.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _visionApiKeyController,
                  obscureText: _visionKeyObscured,
                  decoration: InputDecoration(
                    labelText: 'Cloud Vision API key (optional)',
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
                  child: const Text('Save'),
                ),
                const Divider(height: 40),
                Text(
                  'App update',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'QuetzaLib isn\'t distributed through the Play Store, so '
                  'updates are installed the same way as the first install: '
                  'downloading the latest APK and installing it over this '
                  'app. Your books and settings are kept.',
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
                          : const Text('Check for updates'),
                    ),
                    if (_availableUpdate != null) ...[
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _downloading ? null : _downloadAndInstall,
                        child: Text(
                          _downloading
                              ? 'Downloading… ${(_downloadProgress * 100).round()}%'
                              : 'Download & install',
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
                    'Current version: $_currentVersion',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
    );
  }
}
