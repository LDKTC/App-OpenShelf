import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../models/book_metadata.dart';
import '../settings_service.dart';

/// Looks up book metadata from the National Library of Thailand's Alma
/// catalog over the SRU (Search/Retrieve via URL) protocol, requesting
/// MARCXML records.
///
/// NLT's Alma SRU base URL is not publicly documented and must be
/// configured by the user in Settings (see README.md). Until configured,
/// [lookup] returns null so the caller falls back to Google Books / Open
/// Library.
class NltAlmaSruProvider {
  Future<BookMetadata?> lookup(String isbn13) async {
    final baseUrl = await SettingsService.instance.getSruBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) return null;

    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'version': '1.2',
      'operation': 'searchRetrieve',
      'recordSchema': 'marcxml',
      'maximumRecords': '1',
      'query': 'alma.isbn=$isbn13',
    });

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return null;

    final doc = XmlDocument.parse(response.body);
    final record = doc.findAllElements('record').firstOrNull;
    if (record == null) return null;

    String? subfield(String tag, String code) {
      for (final field in record.findElements('datafield')) {
        if (field.getAttribute('tag') != tag) continue;
        for (final sub in field.findElements('subfield')) {
          if (sub.getAttribute('code') == code) {
            final text = sub.innerText.trim();
            if (text.isNotEmpty) return text;
          }
        }
      }
      return null;
    }

    List<String> allSubfields(String tag, String code) {
      final results = <String>[];
      for (final field in record.findElements('datafield')) {
        if (field.getAttribute('tag') != tag) continue;
        for (final sub in field.findElements('subfield')) {
          if (sub.getAttribute('code') == code) {
            final text = sub.innerText.trim();
            if (text.isNotEmpty) results.add(text);
          }
        }
      }
      return results;
    }

    final titleMain = subfield('245', 'a');
    if (titleMain == null || titleMain.isEmpty) return null;
    final titleSub = subfield('245', 'b');
    final title = [titleMain, titleSub]
        .whereType<String>()
        .join(' ')
        .replaceAll(RegExp(r'[/:;]\s*$'), '')
        .trim();

    final authors = <String>{
      ...allSubfields('100', 'a'),
      ...allSubfields('700', 'a'),
    }.map((a) => a.replaceAll(RegExp(r',\s*$'), '').trim()).toList();

    final publisher = subfield('264', 'b') ?? subfield('260', 'b');
    final publishedDate = subfield('264', 'c') ?? subfield('260', 'c');
    final language = subfield('041', 'a');

    final physical = subfield('300', 'a');
    int? pageCount;
    if (physical != null) {
      final match = RegExp(r'(\d+)\s*p').firstMatch(physical);
      if (match != null) pageCount = int.tryParse(match.group(1)!);
    }

    return BookMetadata(
      isbn13: isbn13,
      title: title,
      authors: authors,
      publisher: publisher?.replaceAll(RegExp(r'[,;]\s*$'), '').trim(),
      publishedDate: publishedDate?.replaceAll(RegExp(r'[.\]]+$'), '').trim(),
      language: language,
      pageCount: pageCount,
      source: 'nlt_alma_sru',
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
