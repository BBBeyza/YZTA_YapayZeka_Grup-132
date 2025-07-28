// lib/services/gemini_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env dosyasından API anahtarı okumak için

class GeminiService {
  // API anahtarı ve model adı constructor ile alınabilir, varsayılan değerler atanır.
  final String apiKey;
  final String modelName;

  // KRİTİK DÜZELTME: _apiBase URL'si. 'modelsML' yerine 'models' kullanılmalı ve sondaki '/' önemli
  // URL şöyle oluşacak: https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=YOUR_KEY
  static const String _apiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/';

  GeminiService({
    String? apiKey,
    String? modelName,
  })  : apiKey = apiKey ?? (dotenv.env['GEMINI_API_KEY'] ?? ''),
        modelName = modelName ?? 'gemini-1.5-pro'; // Varsayılan modeli kontrol edin (gemini-pro veya gemini-1.5-pro-latest gibi)

  Future<String> askGemini(String prompt) async {
    // API anahtarı kontrolü - eğer .env dosyası yoksa veya API anahtarı ayarlanmamışsa
    if (apiKey.isEmpty) {
      print('[Gemini API Hatası] API Anahtarı Ayarlanmadı.');
      return 'Hata: Gemini API anahtarı ayarlanmadı.';
    }

    // URL'yi doğru şekilde oluştur
    // Örnek: https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=YOUR_KEY
    final url = Uri.parse('$_apiBaseUrl$modelName:generateContent?key=$apiKey');
    final headers = const {'Content-Type': 'application/json'};

    // Her istek bağımsız olmalı, conversation history tutulmamalı
    final body = json.encode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      // Safety settings ve generation config eklenebilir
      'generationConfig': {
        'temperature': 0.9,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE'
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug: API yanıtının tam yapısını yazdır
        print('[Gemini API Debug] Tam yanıt: ${json.encode(data)}');

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }

        // Debug: Hangi koşulun başarısız olduğunu belirt
        print('[Gemini API Debug] Yanıt yapısı kontrolü başarısız:');
        print('  - candidates null: ${data['candidates'] == null}');
        print('  - candidates empty: ${data['candidates']?.isEmpty ?? true}');
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          print('  - content null: ${data['candidates'][0]['content'] == null}');
          print('  - parts null: ${data['candidates'][0]['content']?['parts'] == null}');
          print('  - parts empty: ${data['candidates'][0]['content']?['parts']?.isEmpty ?? true}');
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

  // Yeni bir test sorusu için bağımsız istek gönder
  Future<String> askFreshQuestion(String prompt) async {
    // Bu metod özellikle test soruları için kullanılır
    // Her istek tamamen bağımsızdır, önceki konuşma geçmişi yoktur
    return await askGemini(prompt);
  }

  // Debug için modelleri listeleyen geçici metod
  Future<void> listModels() async {
    if (apiKey.isEmpty) {
      print('Hata: Gemini API anahtarı ayarlanmadı.');
      return;
    }

    // KRİTİK DÜZELTME: Modelleri listelerken de doğru API uç noktasını kullanmalıyız.
    // Örnek: https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY
    final url = Uri.parse('${_apiBaseUrl.replaceAll('/models/', '/models')}?key=$apiKey'); // 'models/' yerine 'models' koyduk
    // Alternatif ve daha temiz:
    // final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

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