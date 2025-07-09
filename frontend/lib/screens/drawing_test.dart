import 'package:flutter/material.dart';
import 'package:neurograph/widgets/drawing_canvas.dart';
import 'package:neurograph/services/gemini_service.dart';

// DrawingPoint sınıfının DrawingCanvas.dart içinde tanımlı olduğunu varsayıyorum.
// Eğer tanımlı değilse, onu buraya veya ayrı bir model dosyasına taşımanız gerekir.
// Örneğin:
// class DrawingPoint {
//   Offset point;
//   Paint paint;
//   DrawingPoint({required this.point, required this.paint});
// }

// Talimat bölümü için ayrı bir widget
class InstructionSection extends StatelessWidget {
  final String title;
  final String instruction;
  const InstructionSection({
    required this.title,
    required this.instruction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            instruction,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Buton satırı için ayrı bir widget
class DrawingTestButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onNext;
  final bool isLastTest;
  const DrawingTestButtons({
    required this.onSave,
    required this.onNext,
    required this.isLastTest,
    Key? key,
  }) : super(key: key);

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
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              child: Text(
                isLastTest ? 'Testleri Bitir' : 'Sonraki Test',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DrawingTestScreen extends StatefulWidget {
  const DrawingTestScreen({super.key});

  @override
  State<DrawingTestScreen> createState() => _DrawingTestScreenState();
}

class _DrawingTestScreenState extends State<DrawingTestScreen> {
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();
  final GeminiService _geminiService = GeminiService();

  final Map<String, List<DrawingPoint>> _recordedDrawingData = {};

  int _currentTestIndex = 0;

  final List<Map<String, String>> _testInstructions = [
    {
      'key': 'clock',
      'title': 'Saat Çizimi Testi',
      'instruction':
          'Şimdi ekrana saat 10\'u 10 geçeyi gösteren bir saat çizin. (Kılavuz olmayacaktır, kendi becerinize göre çizin)',
    }, // Talimat güncellendi
    {
      'key': 'spiral',
      'title': 'Spiral Çizimi Testi',
      'instruction': 'Boş ekrana bir spiral çizin.',
    }, // Talimat güncellendi
    {
      'key': 'meander',
      'title': 'Meander Çizimi Testi',
      'instruction': 'Boş ekrana spiral kare çizin.',
    }, // Talimat güncellendi
    {
      'key': 'handwriting',
      'title': 'El Yazısı Testi',
      'instruction':
          'Lütfen "Yarın hava güneşli olacak." cümlesini buraya yazın.',
    },
  ];

  String get _currentTestKey => _testInstructions[_currentTestIndex]['key']!;
  String get _currentTestTitle =>
      _testInstructions[_currentTestIndex]['title']!;
  String get _currentTestInstruction =>
      _testInstructions[_currentTestIndex]['instruction']!;

  bool _isLoading = false;

  void _saveCurrentDrawing() {
    final List<DrawingPoint>? currentPoints = _canvasKey.currentState
        ?.getAllDrawingPoints();

    if (currentPoints != null && currentPoints.isNotEmpty) {
      _recordedDrawingData[_currentTestKey] = currentPoints;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_currentTestTitle} verileri kaydedildi.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hiç çizim verisi bulunamadı!')),
      );
    }
  }

  Future<void> _nextTest() async {
    _saveCurrentDrawing();
    _canvasKey.currentState?.clearCanvas();

    if (_currentTestIndex < _testInstructions.length - 1) {
      setState(() {
        _currentTestIndex++;
      });
    } else {
      await _finalizeDrawingTests();
    }
  }

  Future<void> _finalizeDrawingTests() async {
    setState(() {
      _isLoading = true;
    });

    String drawingSummary = 'Çizim Testleri Özeti:\n';
    _recordedDrawingData.forEach((key, value) {
      drawingSummary +=
          '${_testInstructions.firstWhere((element) => element['key'] == key)['title']}: ${value.length} nokta kaydedildi.\n';
    });
    drawingSummary +=
        '\nDetaylı analiz için bu ham veriler ML modeline gönderilmelidir.';

    final prompt =
        '''
Aşağıdaki çizim ve el yazısı testi verileri özetini inceleyerek genel görsel-motor ve motor beceriler hakkında bir değerlendirme yap. 
Kesin tanı koyma, sadece gözlemlerini belirt. Kullanıcının her test için kaydettiği nokta sayıları: $drawingSummary
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
        title: const Text('Çizim Testi Değerlendirmesi'),
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
        title: Text(_currentTestTitle),
        centerTitle: true, // Başlığı ortala
        backgroundColor: Theme.of(context).colorScheme.primary, // AppBar rengi
        foregroundColor: Colors.white, // AppBar ikon ve yazı rengi
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                InstructionSection(
                  title: _currentTestTitle,
                  instruction: _currentTestInstruction,
                ),
                Expanded(
                  child: Container(
                    // DrawingCanvas yerine basit bir Container kullanabiliriz veya DrawingCanvas'ın kendisi boş bir tuval olabilir.
                    // Buraya DrawingCanvas gelecek
                    child: DrawingCanvas(
                      key: _canvasKey,
                      // Assetsiz olduğu için burada 'child' özelliği kaldırıldı.
                      // Arka planı boş (sadece beyaz veya saydam) olacaktır.
                    ),
                    decoration: BoxDecoration(
                      // Tuvalin etrafına hafif bir çerçeve veya arka plan rengi eklenebilir
                      color: Colors.white, // Tuvalin arka planı beyaz olsun
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ), // Hafif bir çerçeve
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(
                      16.0,
                    ), // Tuvalin etrafında boşluk
                  ),
                ),
                DrawingTestButtons(
                  onSave: _saveCurrentDrawing,
                  onNext: _nextTest,
                  isLastTest: _currentTestIndex >= _testInstructions.length - 1,
                ),
              ],
            ),
    );
  }
}
