// main imports
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:async';

// firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// project imports
import 'package:neurograph/widgets/drawing_canvas.dart';
import 'package:neurograph/models/stroke.dart'; // Bu import kullanılmıyorsa kaldırılabilir
import 'package:neurograph/services/gemini_service.dart';
import '../models/report_model.dart';
// import '../screens/reports_screen.dart'; // Bu import artık gerekli değil

//------------------------------------------------------------------
// Sabit Widget'lar (Değişiklik Gerekmiyor)
//------------------------------------------------------------------

class InstructionSection extends StatelessWidget {
  final String title;
  final String instruction;
  const InstructionSection({
    super.key,
    required this.title,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instruction,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}

class DrawingTestButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onFinish;
  const DrawingTestButtons({
    super.key,
    required this.onSave,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Çizimi Kaydet',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              child: const Text('Testi Bitir', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

//------------------------------------------------------------------
// Ana Ekran Widget'ı (Düzenlenmiş Hali)
//------------------------------------------------------------------

class DrawingTestScreen extends StatefulWidget {
  final String testKey;
  final String testTitle;
  final String testInstruction;

  const DrawingTestScreen({
    super.key,
    required this.testKey,
    required this.testTitle,
    required this.testInstruction,
  });

  @override
  State<DrawingTestScreen> createState() => _DrawingTestScreenState();
}

class _DrawingTestScreenState extends State<DrawingTestScreen> {
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;

  /// Backend URL'sini test anahtarına göre dinamik olarak döndürür.
  String get _backendUrl {
    // TODO: IP adresini kendi yerel IP adresinizle veya sunucu adresinizle değiştirin.
    const String baseUrl = 'http://192.168.1.160:8000'; 
    switch (widget.testKey) {
      case 'spiral':
        return '$baseUrl/spiral/predict_tremor';
      case 'meander':
        return '$baseUrl/meander/predict_meander_tremor';
      case 'clock':
        return '$baseUrl/clock/predict_clock_drawing_score';
      case 'handwriting':
        return '$baseUrl/handwriting/analyze_handwriting';
      default:
        // Varsayılan bir uç nokta veya hata yönetimi
        print('Hata: Bilinmeyen testKey: ${widget.testKey}');
        return '$baseUrl/spiral/predict_tremor';
    }
  }

  /// Geçici olarak çizimi kaydettiğini belirten bir mesaj gösterir.
  void _saveCurrentDrawing() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.testTitle} çizimi kaydedildi.')),
    );
  }

  /// "Testi Bitir" butonuna basıldığında çalışan ana süreç.
  Future<void> _finishTest() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // 1. Çizimi resim verisi (bytes) olarak al
      final drawingImageBytes = await _canvasKey.currentState?.exportDrawingAsPngBytes();
      if (drawingImageBytes == null || drawingImageBytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir çizim yapın!')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 2. Çizimi backend'e gönderip analiz sonucunu al
      final analysisResult = await _analyzeDrawing(drawingImageBytes);

      // 3. Analiz sonucunu Gemini'ye gönderip kullanıcı dostu bir değerlendirme al
      final evaluation = await _getGeminiEvaluation(analysisResult);

      // 4. Test raporunu veritabanına kaydet
      await _saveTestReport(analysisResult, evaluation);

      // 5. Sonucu diyalogda göster. Kullanıcı "Tamam" dediğinde ekran kapanacak.
      if (mounted) {
        await _showEvaluationResult(evaluation);
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
      );
    } finally {
      // Hata durumunda veya süreç normalden farklı biterse loading indicator'ı kapat
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Çizim verisini backend'e gönderir ve ham analiz sonucunu döndürür.
/// Çizim verisini backend'e gönderir ve ham analiz sonucunu döndürür.
  Future<String> _analyzeDrawing(Uint8List drawingImageBytes) async {
    final request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        drawingImageBytes,
        filename: '${widget.testKey}_drawing.png',
        contentType: MediaType('image', 'png'),
      ),
    );

    final response = await request.send().timeout(const Duration(seconds: 30));
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Backend hatası: ${response.statusCode} - $responseBody');
    }

    final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;

    // Analiz sonucunu test türüne göre formatla
    switch (widget.testKey) {
      case 'clock':
        return "Shulman Puanı: ${jsonResponse['shulman_score']} "
            "(Güven: ${(jsonResponse['confidence'] as double).toStringAsFixed(2)})";
      case 'spiral':
      case 'meander':
        final controlProb = jsonResponse['control_probability'] as double;
        final patientProb = jsonResponse['patients_probability'] as double;
        return patientProb > controlProb
            ? "🟡 Titreme Algılandı — Güven: ${patientProb.toStringAsFixed(2)}"
            : "✅ Temiz Çizim — Güven: ${controlProb.toStringAsFixed(2)}";
      case 'handwriting':
        // El yazısı testi için teknik detayları gizle - sadece genel durum bilgisi
        return "El yazısı analizi tamamlandı";
      default:
        return "Test sonucu: ${jsonResponse.toString()}";
    }
  }

  /// Ham analiz sonucunu alıp Gemini'den bir değerlendirme metni ister.
  Future<String> _getGeminiEvaluation(String analysisResult) async {
    String prompt;
    
    if (widget.testKey == 'handwriting') {
      // El yazısı testi için özel prompt - teknik sonuçları kullanma
      prompt = '''
Kullanıcının yaptığı el yazısı testini değerlendirir misin? El yazısının genel okunabilirliği, düzenliliği ve akıcılığı hakkında genel bir değerlendirme yap. 

Test Talimatı: "${widget.testInstruction}"

Bu el yazısı testine dayanarak:
- Yazının genel okunabilirliği
- Harflerin düzenliliği
- Yazı akıcılığı
- Genel motor beceri durumu

konularında kullanıcıya anlaşılır, pozitif ve kısa bir değerlendirme raporla. Teknik puanlardan veya sayısal değerlerden bahsetme.
''';
    } else {
      // Diğer testler için mevcut prompt
      prompt = '''
Kullanıcının yaptığı "${widget.testTitle}" adlı çizim testinin sonuçlarını değerlendirir misin? Eğer gelen test saat çizimi ise Shulman puanını kullanarak değerlendirme yap. Spiral ve meander testleri için ise titreme olasılıklarını kullanarak bir değerlendirme yap. El yazısı testi için ise el yazısının genel durumunu değerlendir diğer test türlerinden ve puanlamasından bahsetme. 
Test Talimatı: "${widget.testInstruction}"
Analiz Sonucu: "$analysisResult"

Bu bilgilere dayanarak, çizimin genel durumunu ve varsa potansiyel anomalileri kullanıcıya anlaşılır, kısa ve tıbbi olmayan bir dille raporla.
''';
    }
    
    return await _geminiService.askGemini(prompt);
  }
  
  /// Analiz ve değerlendirme sonuçlarını içeren raporu Firestore'a kaydeder.
  Future<void> _saveTestReport(String analysisResult, String evaluation) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      String reportContent;
      
      if (widget.testKey == 'handwriting') {
        // El yazısı testi için sadece değerlendirmeyi kaydet
        reportContent = evaluation;
      } else {
        // Diğer testler için hem analiz hem değerlendirme
        reportContent = '''
Test Türü: ${widget.testKey.toUpperCase()}
Analiz Sonucu: $analysisResult
Değerlendirme: $evaluation
''';
      }

      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${widget.testTitle} Test Raporu',
        content: reportContent,
        date: DateTime.now(),
        type: 'drawing',
        userId: user.uid,
      );

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(report.id)
          .set(report.toMap());
    } catch (e) {
      // Hata olsa bile süreç devam etmeli, sadece konsola yazdır.
      print('Rapor kaydedilirken hata: $e');
      // İsteğe bağlı olarak kullanıcıya bir uyarı gösterebilirsiniz.
      // throw Exception('Rapor kaydedilemedi: $e');
    }
  }

  /// Değerlendirme sonucunu gösteren ve kapatıldığında bir önceki ekrana dönen diyalogu açar.
  Future<void> _showEvaluationResult(String evaluation) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false, // Dışarı tıklayarak kapatmayı engelle
      builder: (dialogContext) => AlertDialog(
        title: Text('${widget.testTitle} Değerlendirme Raporu'),
        content: SingleChildScrollView(child: Text(evaluation)),
        actions: [
          TextButton(
            onPressed: () {
              // İlk pop diyalogu kapatır.
              Navigator.of(dialogContext).pop(); 
              // İkinci pop çizim ekranını (DrawingTestScreen) kapatır.
              Navigator.of(context).pop(); 
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testTitle),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                InstructionSection(
                  title: widget.testTitle,
                  instruction: widget.testInstruction,
                ),
                Expanded(child: DrawingCanvas(key: _canvasKey)),
                DrawingTestButtons(
                  onSave: _saveCurrentDrawing,
                  onFinish: _finishTest,
                ),
              ],
            ),
    );
  }
}