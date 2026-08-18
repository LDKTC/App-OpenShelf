import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quetzalib/services/ocr_service.dart';
import 'package:quetzalib/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OcrService with a Cloud Vision API key configured', () {
    late String photoPath;
    late XFile photo;

    setUp(() async {
      await SettingsService.instance.setCloudVisionApiKey('test-api-key');
      final file = await File(
        '${Directory.systemTemp.path}/ocr_service_test_photo.jpg',
      ).create();
      await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
      photoPath = file.path;
      photo = XFile(photoPath);
    });

    tearDown(() async {
      await SettingsService.instance.setCloudVisionApiKey(null);
      final file = File(photoPath);
      if (await file.exists()) await file.delete();
    });

    test('returns the recognized full text on a successful response',
        () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'vision.googleapis.com');
        expect(request.url.queryParameters['key'], 'test-api-key');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final requests = body['requests'] as List<dynamic>;
        final imageRequest = requests.first as Map<String, dynamic>;
        expect(
          (imageRequest['imageContext']
              as Map<String, dynamic>)['languageHints'],
          ['th', 'en'],
        );

        return http.Response(
          jsonEncode({
            'responses': [
              {
                'fullTextAnnotation': {'text': 'ชื่อหนังสือ\nสำนักพิมพ์'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result =
          await OcrService(client: client).recognizeText(photo);

      expect(result, 'ชื่อหนังสือ\nสำนักพิมพ์');
    });

    test('returns empty string when no text is found', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'responses': [<String, dynamic>{}],
          }),
          200,
        );
      });

      final result =
          await OcrService(client: client).recognizeText(photo);

      expect(result, '');
    });

    test('throws when the HTTP request does not return 200', () async {
      final client = MockClient((request) async {
        return http.Response('server error', 500);
      });

      await expectLater(
        OcrService(client: client).recognizeText(photo),
        throwsA(isA<Exception>()),
      );
    });

    test('throws with the API error message when Cloud Vision reports one',
        () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'responses': [
              {
                'error': {'message': 'API key not valid.'},
              },
            ],
          }),
          200,
        );
      });

      await expectLater(
        OcrService(client: client).recognizeText(photo),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API key not valid.'),
          ),
        ),
      );
    });
  });
}
