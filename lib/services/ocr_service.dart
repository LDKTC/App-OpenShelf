import 'dart:convert';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

import 'settings_service.dart';

/// Recognizes text in a photo so it can be reviewed and applied to a book
/// field (title, author, illustrator, ISBN, publisher).
///
/// Uses the Cloud Vision API when the user has configured an API key in
/// Settings — it's accurate for Thai as well as Latin script, at the cost
/// of a network call billed to that key. Without a key configured, this
/// falls back to on-device ML Kit text recognition: free and offline, but
/// Latin-script only, so Thai-titled books won't be recognized.
class OcrService {
  OcrService({http.Client? client}) : _client = client ?? http.Client();

  static const _visionEndpoint =
      'https://vision.googleapis.com/v1/images:annotate';

  final http.Client _client;

  Future<String> recognizeText(String imagePath) async {
    final apiKey = await SettingsService.instance.getCloudVisionApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      return _recognizeWithCloudVision(imagePath, apiKey);
    }
    return _recognizeOnDevice(imagePath);
  }

  Future<String> _recognizeOnDevice(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }

  Future<String> _recognizeWithCloudVision(
    String imagePath,
    String apiKey,
  ) async {
    final bytes = await File(imagePath).readAsBytes();
    final uri = Uri.parse(
      _visionEndpoint,
    ).replace(queryParameters: {'key': apiKey});

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'requests': [
              {
                'image': {'content': base64Encode(bytes)},
                'features': [
                  {'type': 'TEXT_DETECTION'},
                ],
                'imageContext': {
                  'languageHints': ['th', 'en'],
                },
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Cloud Vision request failed (HTTP ${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['responses'] as List<dynamic>?;
    if (results == null || results.isEmpty) return '';

    final first = results.first as Map<String, dynamic>;
    final error = first['error'] as Map<String, dynamic>?;
    if (error != null) {
      throw Exception(error['message'] as String? ?? 'Cloud Vision error.');
    }

    final fullTextAnnotation = first['fullTextAnnotation'] as Map<String, dynamic>?;
    return (fullTextAnnotation?['text'] as String?)?.trim() ?? '';
  }
}
