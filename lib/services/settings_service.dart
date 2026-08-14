import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-configurable app settings, in particular the National
/// Library of Thailand (NLT) Alma SRU endpoint, whose exact host is
/// specific to NLT's Alma tenant and isn't publicly documented — see
/// README.md for how to find and enter it.
class SettingsService {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  static const _keySruBaseUrl = 'nlt_sru_base_url';
  static const _keySruInstitutionCode = 'nlt_sru_institution_code';

  static const defaultInstitutionCode = '66NLT_INST';

  Future<String?> getSruBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySruBaseUrl);
  }

  Future<void> setSruBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_keySruBaseUrl);
    } else {
      await prefs.setString(_keySruBaseUrl, url.trim());
    }
  }

  Future<String> getSruInstitutionCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySruInstitutionCode) ?? defaultInstitutionCode;
  }

  Future<void> setSruInstitutionCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySruInstitutionCode, code.trim());
  }
}
