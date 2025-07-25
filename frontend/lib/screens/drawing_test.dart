import 'package:flutter/material.dart';
import 'package:neurograph/widgets/drawing_canvas.dart';
import 'package:neurograph/models/stroke.dart'; // DrawingPoint yerine Stroke'tan alıyoruz
import 'package:neurograph/services/gemini_service.dart';

// Talimat bölümü için ayrı bir widget
class InstructionSection extends StatelessWidget {
  final String title;
  final String instruction;
  const InstructionSection({ // super.key burada kullanılıyor
    super.key, // 'Key? key' yerine super.key
    required this.title,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Sola daya
        children: [
          // Başlık kaldırıldı, SizedBox da kaldırılabilir
          // const SizedBox(height: 10),
          Text(
            instruction,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16, // Font boyutu ayarlandı
            ),
            textAlign: TextAlign.start, // Sola hizala
          ),
        ],
      ),
    );
  }
}

// Buton satırı için ayrı bir widget
class DrawingTestButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onFinish;
  const DrawingTestButtons({ // super.key burada kullanılıyor
    super.key, // 'Key? key' yerine super.key
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
              child: const Text(
                'Testi Bitir',
                style: TextStyle(fontSize: 16),
              ),
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

  const DrawingTestScreen({ // super.key burada kullanılıyor
    super.key, // 'Key? key' yerine super.key
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

  List<DrawingPoint>? _currentDrawingPoints;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _saveCurrentDrawing() {
    final List<DrawingPoint>? points = _canvasKey.currentState?.getAllDrawingPoints();

    if (points != null && points.isNotEmpty) {
      _currentDrawingPoints = points;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.testTitle} verileri kaydedildi.')),
      );
    } else {
      _currentDrawingPoints = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hiç çizim verisi bulunamadı!')),
      );
    }
  }

  Future<void> _finishTest() async {
    _saveCurrentDrawing();

    setState(() {
      _isLoading = true;
    });

    String drawingSummary = '';
    if (_currentDrawingPoints != null && _currentDrawingPoints!.isNotEmpty) {
      drawingSummary = '${widget.testTitle} için ${_currentDrawingPoints!.length} nokta kaydedildi.';
    } else {
      drawingSummary = '${widget.testTitle} için hiç çizim verisi kaydedilmedi.';
    }

    final prompt =
    '''
Kullanıcının yaptığı "${widget.testTitle}" adlı çizim testinin sonuçlarını değerlendirir misin?
Test Talimatı: "${widget.testInstruction}"
Kaydedilen çizim verisi özeti: $drawingSummary
(Not: Bu ham veri, ML modeline gönderildiğinde daha detaylı analiz edilebilir. Şimdilik sadece bu özete dayanarak genel bir değerlendirme yap.)
''';
    final evaluation = await _geminiService.askGemini(prompt);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.testTitle} Değerlendirmesi'),
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