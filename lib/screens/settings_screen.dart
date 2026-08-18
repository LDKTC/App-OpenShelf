import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../state/library_provider.dart';
import '../widgets/app_update_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _visionApiKeyController = TextEditingController();
  bool _loading = true;
  bool _visionKeyObscured = true;

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

  @override
  void dispose() {
    _visionApiKeyController.dispose();
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
                const AppUpdateSection(),
              ],
            ),
    );
  }
}
