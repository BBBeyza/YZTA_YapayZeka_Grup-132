// lib/services/gemini_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // API anahtarı ve model adı constructor ile alınabilir, varsayılan değerler atanır.
  final String apiKey;
  final String modelName;
  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1beta/models/';

  GeminiService({
    String? apiKey,
    String? modelName,
  })  : apiKey = apiKey ?? (dotenv.env['GEMINI_API_KEY'] ?? ''),
        modelName = modelName ?? 'gemini-2.5-flash';

  Future<String> askGemini(String prompt) async {
    if (apiKey == 'YOUR_GEMINI_API_KEY' || apiKey.isEmpty) {
      return 'Hata: Gemini API anahtarı ayarlanmadı. Lütfen "lib/services/gemini_service.dart" dosyasını kontrol edin.';
    }

    final url = Uri.parse('$_apiBase$modelName:generateContent?key=$apiKey');
    final headers = const {'Content-Type': 'application/json'};
    final body = json.encode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
        return 'Yanıt alınamadı veya boş geldi.';
      } else {
        print('[Gemini API Hatası] ${response.statusCode} - ${response.body}');
        return 'API bağlantı hatası: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      print('[Gemini API] İstek gönderme hatası: $e');
      return 'İstek gönderilirken bir hata oluştu: $e';
    }
  }

  // Debug için modelleri listeleyen geçici metod
  Future<void> listModels() async {
    if (apiKey == 'YOUR_GEMINI_API_KEY' || apiKey.isEmpty) {
      print('Hata: Gemini API anahtarı ayarlanmadı.');
      return;
    }

    final url = Uri.parse('$_apiBase?key=$apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('Mevcut Gemini Modelleri:');
        print(json.decode(response.body));
      } else {
        print('[Gemini API] Modelleri listelerken hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[Gemini API] Modelleri listeleme isteği gönderme hatası: $e');
    }
  }
}
