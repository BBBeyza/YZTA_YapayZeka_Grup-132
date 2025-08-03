import 'package:flutter/material.dart';
import 'package:neurograph/widgets/drawing_canvas.dart';
import 'package:neurograph/models/stroke.dart';
import 'package:neurograph/services/gemini_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart'; // MediaType için

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
  final String testKey; // 'spiral', 'meander', 'clock' veya 'handwriting'
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
    const String baseUrl = 'http://192.168.1.160:8000';
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

  Future<void> _finishTest() async {
    setState(() {
      _isLoading = true;
    });

    Uint8List? drawingImageBytes;
    try {
      drawingImageBytes = await _canvasKey.currentState
          ?.exportDrawingAsPngBytes();
      if (drawingImageBytes == null || drawingImageBytes.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hiç çizim verisi bulunamadı veya resim oluşturulamadı!',
            ),
          ),
        );
        return;
      }
    } catch (e) {
      print('Çizim resmi dışa aktarılırken hata: $e');
      drawingImageBytes = null;
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çizim resmi dışa aktarılırken hata oluştu: $e'),
        ),
      );
      return;
    }

    String classificationResult = "Analiz yapılamadı.";
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'image', 
          drawingImageBytes,
          filename: 'drawing.png',
          contentType: MediaType('image', 'png'),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('Backend yanıtı: $responseBody');

        try {
          final Map<String, dynamic> jsonResponse = json.decode(responseBody);

          if (widget.testKey == 'clock') {
            final int shulmanScore = jsonResponse['shulman_score'];
            final double confidence = jsonResponse['confidence'];
            classificationResult =
                "Shulman Puanı: $shulmanScore (Güven: ${confidence.toStringAsFixed(2)})";
          } else if (widget.testKey == 'spiral' || widget.testKey == 'meander') {
            final double controlProbability = jsonResponse['control_probability'];
            final double patientsProbability = jsonResponse['patients_probability'];
            if (patientsProbability > controlProbability) {
              classificationResult =
                  "🟡 Titreme Algılandı — Güven: ${patientsProbability.toStringAsFixed(2)}";
            } else {
              classificationResult =
                  "✅ Temiz Çizim — Güven: ${controlProbability.toStringAsFixed(2)}";
            }
          } else if (widget.testKey == 'handwriting') {
            final List<dynamic> lineResults = jsonResponse['line_analysis_results'];
            if (lineResults.isNotEmpty) {
              // Enhanced handwriting analysis results
              final double overallQuality = jsonResponse['overall_quality_score'] ?? 0.0;
              final String qualityLevel = jsonResponse['overall_handwriting_quality'] ?? 'unknown';
              final double micrographyScore = jsonResponse['overall_micrography_score'] ?? 0.0;
              final String micrographySeverity = jsonResponse['micrography_severity'] ?? 'none';
                             final double sizeConsistency = jsonResponse['size_consistency_score'] ?? 0.0;
               final double alignmentQuality = jsonResponse['alignment_quality_score'] ?? 0.0;
               final double spacingRegularity = jsonResponse['spacing_regularity_score'] ?? 0.0;
               final double baselineStability = jsonResponse['baseline_stability_score'] ?? 0.0;
               
                               // Canvas size analysis - only show warnings for extreme cases
                String canvasSizeNote = "";
                if (lineResults.isNotEmpty) {
                  final firstLine = lineResults.first;
                  final canvasAnalysis = firstLine['canvas_size_analysis'] ?? 'normal';
                  switch (canvasAnalysis) {
                    case 'characters_too_small':
                      canvasSizeNote = "💡 Harfler çok küçük - daha büyük yazmayı deneyin";
                      break;
                    case 'characters_too_large':
                      canvasSizeNote = "💡 Harfler çok büyük - daha küçük yazmayı deneyin";
                      break;
                    case 'optimal_size':
                    default:
                      canvasSizeNote = ""; // Don't show anything for optimal size
                  }
                }
              
              String qualityEmoji = "✅";
              if (qualityLevel == "poor") qualityEmoji = "❌";
              else if (qualityLevel == "fair") qualityEmoji = "⚠️";
              else if (qualityLevel == "good") qualityEmoji = "✅";
              
              String micrographyEmoji = "";
              if (micrographySeverity == "severe") micrographyEmoji = "🔴";
              else if (micrographySeverity == "moderate") micrographyEmoji = "🟡";
              else if (micrographySeverity == "mild") micrographyEmoji = "🟠";
              else micrographyEmoji = "✅";
              
                             classificationResult =
                   "$qualityEmoji Metin Kalitesi: ${qualityLevel.toUpperCase()}\n"
                   "$micrographyEmoji Mikrografi: ${micrographySeverity.toUpperCase()} (${micrographyScore.toStringAsFixed(2)})\n"
                   "📊 Medyan harf yüksekliğinden %40 farklı olan harfler: ${(micrographyScore * 100).toStringAsFixed(0)}%\n"
                   "$canvasSizeNote";
            } else {
              classificationResult = "El yazısı tespit edilemedi.";
            }
          }

        } on FormatException catch (e) {
          classificationResult =
              "Backend yanıtı işlenirken hata: Yanıt bir JSON değil. Hata: $e";
        } catch (e) {
          classificationResult =
              "Backend yanıtı işlenirken beklenmeyen hata: $e";
        }
      } else {
        String errorBody = await response.stream.bytesToString();
        classificationResult =
            "Backend hatası: ${response.statusCode} - $errorBody";
        print("Backend Hata Yanıtı: $errorBody");
      }
    } catch (e) {
      print('Backend ile iletişim hatası: $e');
      classificationResult = "Backend ile iletişim hatası: $e";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    final prompt =
        '''
Kullanıcının yaptığı "${widget.testTitle}" adlı ${widget.testKey} çizim testinin sonuçlarını değerlendirir misin?
Test Talimatı: "${widget.testInstruction}"
Cihaz üzerindeki ML modelinden gelen analiz sonucu (backend'den): "$classificationResult"

Bu bilgilere dayanarak, çizimin genel durumunu ve varsa potansiyel anomalileri kullanıcıya anlaşılır bir dille kısa bir şekilde raporla. Bilimsel terimlerden kaçın, nazik ve destekleyici ol. Sadece verilen bilgilere odaklan, çizim hakkında doğrudan görsel yorum yapma. Yüzdelik olarak skorunu belirt ve kullanıcıya çizimlerini geliştirmesi için önerilerde bulun. Eğer çizim temizse, bunu da belirt.
''';
    final evaluation = await _geminiService.askGemini(prompt);

    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.testTitle} Değerlendirme Raporu'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text(evaluation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
                Expanded(
                  child: DrawingCanvas(
                    key: _canvasKey,
                  ),
                ),
                DrawingTestButtons(
                  onSave: _saveCurrentDrawing,
                  onFinish: _finishTest,
                ),
              ],
            ),
    );
  }
}
