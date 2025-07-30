import 'package:flutter/material.dart';
import 'package:neurograph/widgets/drawing_canvas.dart';
import 'package:neurograph/models/stroke.dart'; // Bu modelin var olduğunu varsayıyorum
import 'package:neurograph/services/gemini_service.dart'; // Bu servisin var olduğunu varsayıyorum
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart'; // MediaType için

// --- InstructionSection Widget ---
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

// --- DrawingTestButtons Widget ---
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

// --- DrawingTestScreen Class ---
class DrawingTestScreen extends StatefulWidget {
  final String testKey; // 'spiral' veya 'meander'
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

  // Backend URL'sini testKey'e göre dinamik olarak belirle
  String get _backendUrl {
    const String baseUrl = 'http://192.168.1.160:8000'; // Backend'inizin ana URL'si
    if (widget.testKey == 'spiral') {
      // Spiral testi için backend endpoint'i
      return '$baseUrl/spiral/predict_tremor'; 
    } else if (widget.testKey == 'meander') {
      // Meander testi için backend endpoint'i
      return '$baseUrl/meander/predict_meander_tremor';
    }
    // Bilinmeyen bir testKey gelirse varsayılan veya hata durumu
    print('Hata: Bilinmeyen testKey: ${widget.testKey}');
    return '$baseUrl/spiral/predict_tremor'; // Varsayılan olarak spiral endpoint'ini kullan
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

      // Hata Ayıklama: Orijinal çizim baytlarını dosyaya kaydet (isteğe bağlı)
      final directory = await getApplicationDocumentsDirectory();
      final originalFilePath =
          '${directory.path}/original_drawing_${widget.testKey}_${DateTime.now().millisecondsSinceEpoch}.png';
      final originalFile = File(originalFilePath);
      await originalFile.writeAsBytes(drawingImageBytes);
      print('Orijinal çizim kaydedildi: $originalFilePath');
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

    String tremorClassificationResult = "Tremor analizi yapılamadı.";
    try {
      // Çizim PNG baytlarını backend sunucusuna gönder
      var request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // Backend'de beklenen alan adı (FastAPI'de File(...) veya Form(...))
          drawingImageBytes,
          filename: 'drawing.png',
          contentType: MediaType('image', 'png'), // http_parser'dan MediaType
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('Backend yanıtı: $responseBody');

        try {
          final Map<String, dynamic> jsonResponse = json.decode(responseBody);
          // Backend'den gelen tahminin JSON formatına göre key isimlerini ayarlayın
          final double controlProbability = jsonResponse['control_probability'];
          final double patientsProbability =
              jsonResponse['patients_probability'];

          if (patientsProbability > controlProbability) {
            tremorClassificationResult =
                "🟡 Titreme Algılandı — Güven: ${patientsProbability.toStringAsFixed(2)}";
          } else {
            tremorClassificationResult =
                "✅ Temiz Yazım — Güven: ${controlProbability.toStringAsFixed(2)}";
          }
        } catch (e) {
          tremorClassificationResult =
              "Backend yanıtı işlenirken hata: $e. Yanıt: $responseBody";
        }
      } else {
        tremorClassificationResult =
            "Backend hatası: ${response.statusCode} - ${await response.stream.bytesToString()}";
      }
    } catch (e) {
      print('Backend ile iletişim hatası: $e');
      tremorClassificationResult = "Backend ile iletişim hatası: $e";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    // Gemini'ye nihai raporlama prompt'unu gönder (ML sonucuyla birlikte)
    final prompt =
        '''
Kullanıcının yaptığı "${widget.testTitle}" adlı ${widget.testKey} çizim testinin sonuçlarını değerlendirir misin?
Test Talimatı: "${widget.testInstruction}"
Cihaz üzerindeki ML modelinden gelen tremor sınıflandırma sonucu (backend'den): "$tremorClassificationResult"

Bu bilgilere dayanarak, çizimin genel tremor durumunu ve varsa potansiyel anomalileri kullanıcıya anlaşılır bir dille raporla. Bilimsel terimlerden kaçın, nazik ve destekleyici ol. Sadece verilen bilgilere odaklan, çizim hakkında doğrudan görsel yorum yapma.
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
              Text(
                'ML Model Analizi: $tremorClassificationResult',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Genel Değerlendirme (Gemini):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
