import 'package:flutter/material.dart';
import 'package:neurograph/screens/drawing_test.dart';
import 'package:neurograph/screens/tutorial_screen.dart';

class DrawingTestSelectionScreen extends StatefulWidget {
  const DrawingTestSelectionScreen({super.key});

  @override
  State<DrawingTestSelectionScreen> createState() => _DrawingTestSelectionScreenState();
}

class _DrawingTestSelectionScreenState extends State<DrawingTestSelectionScreen> {
  static const String _meanderTutorialVideoUrl = 'assets/videos/MeanderTutorialVideo.mp4';
  static const String _spiralTutorialVideoUrl = 'assets/videos/SpiralTutorialVideo.mp4';

  final List<Map<String, String>> _testOptions = const [
    {
      'key': 'clock',
      'title': 'Saat Çizimi Testi',
    },
    {
      'key': 'spiral',
      'title': 'Spiral Çizimi Testi',
    },
    {
      'key': 'meander',
      'title': 'Meander Çizimi Testi',
    },
    {
      'key': 'handwriting',
      'title': 'El Yazısı Testi',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Çizim Testleri'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lütfen yapmak istediğiniz çizim testini seçin:',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.85,
                ),
                itemCount: _testOptions.length,
                itemBuilder: (context, index) {
                  final test = _testOptions[index];
                  return DrawingSelectionCard(
                    title: test['title']!,
                    onTap: () {
                      _handleTestSelection(context, test['key']!, test['title']!);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTestSelection(BuildContext context, String testKey, String testTitle) {
    final String instruction = _getInstructionForKey(testKey);
    String videoUrl = '';

    if (testKey == 'meander') {
      videoUrl = _meanderTutorialVideoUrl;
    } else if (testKey == 'spiral') {
      videoUrl = _spiralTutorialVideoUrl;
    }

    if (videoUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TutorialScreen(
            testKey: testKey,
            testTitle: testTitle,
            instruction: instruction,
            videoUrl: videoUrl,
          ),
        ),
      );
    } else {
      _navigateToDrawingTest(context, testKey, testTitle, instruction);
    }
  }

  void _navigateToDrawingTest(BuildContext context, String testKey, String testTitle, String instruction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingTestScreen(
          testKey: testKey,
          testTitle: testTitle,
          testInstruction: instruction,
        ),
      ),
    );
  }

  String _getInstructionForKey(String key) {
    switch (key) {
      case 'clock':
        return 'Şimdi ekrana saat 10\'u 10 geçeyi gösteren bir saat çizin. Saatin tüm öğelerini (sayılar, akrep, yelkovan) eklemeyi unutmayın.';
      case 'spiral':
        return 'Ekranın ortasına, mümkün olduğunca düzgün ve tutarlı bir içe doğru (veya dışa doğru) spiral çizin. Çizgilerinizin birbirine değmemesine ve merkeze doğru düzenli bir şekilde daralmasına dikkat edin.';
      case 'meander':
        return 'Ekranın ortasına, birbirine paralel çizgilerden oluşan, köşeli ve düzenli bir "meander" (spiral kare) deseni çizin. Köşelerin keskin ve çizgilerin birbirine yakın ama değmeyen şekilde olmasına özen gösterin.';
      case 'handwriting':
        return 'Lütfen aşağıdaki cümleyi ekrana okunaklı ve doğal el yazınızla yazın: "Yarın hava güneşli olacak." Yazınızın boyutu ve eğimi doğal olsun.';
      default:
        return 'Bu test için talimat bulunamadı.';
    }
  }
}

// DrawingSelectionCard widget'ı aynı kalır.
class DrawingSelectionCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const DrawingSelectionCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 160.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 24,
        height: cardHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFDDE5F0),
              child: Icon(Icons.draw, size: 40, color: Color(0xFF72B0D3)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}