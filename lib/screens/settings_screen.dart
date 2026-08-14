import 'package:flutter/material.dart';

import '../services/metadata_providers/nlt_alma_sru_provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sruUrlController = TextEditingController();
  bool _loading = true;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = await SettingsService.instance.getSruBaseUrl();
    _sruUrlController.text = url ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await SettingsService.instance.setSruBaseUrl(_sruUrlController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved.')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    await SettingsService.instance.setSruBaseUrl(_sruUrlController.text);
    try {
      // A well-known Thai ISBN prefix is enough to exercise the endpoint;
      // a null result here just means "no record", which still proves the
      // endpoint is reachable and returning a well-formed SRU response.
      await NltAlmaSruProvider().lookup('9786160000000');
      setState(() => _testResult = 'Endpoint reachable and responded.');
    } catch (e) {
      setState(() => _testResult = 'Could not reach endpoint: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  void dispose() {
    _sruUrlController.dispose();
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
                  'National Library of Thailand (NLT) lookup',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Thai-language ISBNs (prefix 978-616 or 978-974) are looked '
                  'up against NLT\'s Alma catalog via SRU. NLT\'s SRU base URL '
                  'is specific to their Alma tenant and isn\'t public — ask '
                  'NLT/Alma support for it, or find it under Alma Configuration '
                  '> Resources > Search > SRU. It typically looks like '
                  'https://<region>.alma.exlibrisgroup.com/view/sru/66NLT_INST. '
                  'Until this is set, Thai books fall back to Google Books / '
                  'Open Library, which may not have them.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sruUrlController,
                  decoration: const InputDecoration(
                    labelText: 'SRU base URL',
                    hintText: 'https://<region>.alma.exlibrisgroup.com/view/sru/66NLT_INST',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(onPressed: _save, child: const Text('Save')),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _testing ? null : _testConnection,
                      child: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Test connection'),
                    ),
                  ],
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 12),
                  Text(_testResult!),
                ],
              ],
            ),
    );
  }
}
