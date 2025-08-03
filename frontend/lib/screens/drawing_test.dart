import 'package:flutter/material.dart';
import 'package:neurograph/widgets/drawing_canvas.dart';
import 'package:neurograph/models/stroke.dart';
import 'package:neurograph/services/gemini_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../screens/reports_screen.dart';

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

  String get _backendUrl {
    const String baseUrl = 'http://10.0.2.2:8000';
    if (widget.testKey == 'spiral') {
      return '$baseUrl/spiral/predict_tremor';
    } else if (widget.testKey == 'meander') {
      return '$baseUrl/meander/predict_meander_tremor';
    } else if (widget.testKey == 'clock') {
      return '$baseUrl/clock/predict_clock_drawing_score';
    } else if (widget.testKey == 'handwriting') {
      return '$baseUrl/handwriting/analyze_handwriting';
    }
    print('Hata: Bilinmeyen testKey: ${widget.testKey}');
    return '$baseUrl/spiral/predict_tremor';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _saveCurrentDrawing() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.testTitle} çizimi kaydedildi.')),
    );
  }

  String _parseResult(Map<String, dynamic> jsonResponse) {
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

      default:
        return "Test sonucu: ${jsonResponse.toString()}";
    }
  }

  Future<void> _showResult(dynamic result) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.testTitle} Sonucu'),
        content: SingleChildScrollView(child: Text(result.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishTest() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // 1. Çizimi al
      final drawingImageBytes = await _canvasKey.currentState
          ?.exportDrawingAsPngBytes();
      if (drawingImageBytes == null || drawingImageBytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çizim alınamadı! Lütfen tekrar deneyin.'),
          ),
        );
        return;
      }

      // 2. Backend'e gönder
      var request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          drawingImageBytes,
          filename: '${widget.testKey}_drawing.png',
          contentType: MediaType('image', 'png'),
        ),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception(
          'Backend hatası: ${response.statusCode} - $responseBody',
        );
      }

      final jsonResponse = json.decode(responseBody);
      final analysisResult = _parseAnalysisResult(jsonResponse);

      // 3. Gemini ile değerlendirme yap
      final evaluation = await _getGeminiEvaluation(analysisResult);

      // 4. Raporu kaydet ve ekranı güncelle
      await _saveAndShowReport(analysisResult, evaluation);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseAnalysisResult(Map<String, dynamic> jsonResponse) {
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

      default:
        return "Test sonucu: ${jsonResponse.toString()}";
    }
  }

  Future<void> _saveAndShowReport(
    String analysisResult,
    String evaluation,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final report = Report(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${widget.testTitle} Raporu',
      content:
          '''
**Test Türü:** ${widget.testKey.toUpperCase()}
**Analiz Sonucu:** $analysisResult
**Değerlendirme:** $evaluation
''',
      date: DateTime.now(),
      type: 'drawing',
      userId: user.uid,
    );

    await FirebaseFirestore.instance
        .collection('reports')
        .doc(report.id)
        .set(report.toMap());

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => ReportsScreen()),
      (route) => false,
    );
  }

  String _parseSpiralResult(Map<String, dynamic> json) {
    final controlProb = json['control_probability'] as double;
    final patientProb = json['patients_probability'] as double;

    return patientProb > controlProb
        ? "🟡 Titreme Algılandı (Güven: ${patientProb.toStringAsFixed(2)})"
        : "✅ Normal Çizim (Güven: ${controlProb.toStringAsFixed(2)})";
  }

  Future<String> _analyzeDrawing(Uint8List drawingImageBytes) async {
    final request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        drawingImageBytes,
        filename: 'drawing.png',
        contentType: MediaType('image', 'png'),
      ),
    );

    final response = await request.send().timeout(const Duration(seconds: 30));
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Backend hatası: ${response.statusCode} - $responseBody');
    }

    final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;

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

      default:
        return "Test sonucu: ${jsonResponse.toString()}";
    }
  }

  Future<void> _showEvaluationResult(String evaluation) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dokunmayla kapatamasın
      builder: (context) => AlertDialog(
        title: Text('${widget.testTitle} Sonucu'),
        content: SingleChildScrollView(child: Text(evaluation)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pop(context); // Çizim ekranından çık
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<String> _getGeminiEvaluation(String analysisResult) async {
    final prompt =
        '''
Kullanıcının yaptığı "${widget.testTitle}" adlı ${widget.testKey} çizim testinin sonuçlarını değerlendirir misin?
Test Talimatı: "${widget.testInstruction}"
Analiz Sonucu: "$analysisResult"

Bu bilgilere dayanarak, çizimin genel durumunu ve varsa potansiyel anomalileri kullanıcıya anlaşılır bir dille kısa bir şekilde raporla.
''';
    return await _geminiService.askGemini(prompt);
  }

  Future<void> _showResultDialog(String evaluation) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('${widget.testTitle} Değerlendirme Raporu'),
        content: SingleChildScrollView(child: Text(evaluation)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTestReport(String analysisResult, String evaluation) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${widget.testTitle} Test Raporu',
        content:
            '''
**Test Türü:** ${widget.testKey.toUpperCase()}
**Analiz Sonucu:** $analysisResult
**Değerlendirme:** $evaluation
''',
        date: DateTime.now(),
        type: 'drawing',
        userId: user.uid,
      );

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(report.id)
          .set(report.toMap());
    } catch (e) {
      print('Rapor kaydedilirken hata: $e');
      throw Exception('Rapor kaydedilemedi: $e');
    }
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
