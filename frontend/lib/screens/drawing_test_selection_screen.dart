import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:neurograph/screens/drawing_test.dart';
import 'tutorial_screen.dart';

class DrawingTestSelectionScreen extends StatefulWidget {
  const DrawingTestSelectionScreen({super.key});

  @override
  State<DrawingTestSelectionScreen> createState() => _DrawingTestSelectionScreenState();
}

class _DrawingTestSelectionScreenState extends State<DrawingTestSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F4FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 20.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE1BEE7),
                Color(0xFFD1C4E9),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              '🎨 Çizim Testleri',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                shadows: [
                  Shadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F4FF),
              Color(0xFFEDE7F6),
            ],
          ),
        ),
        child: const _DrawingTestSelectionScreenContent(),
      ),
    );
  }
}

class _DrawingTestSelectionScreenContent extends StatelessWidget {
  const _DrawingTestSelectionScreenContent({super.key});

  static const String _meanderTutorialVideoUrl = 'assets/videos/MeanderTutorialVideo.mp4';
  static const String _spiralTutorialVideoUrl = 'assets/videos/SpiralTutorialVideo.mp4';

  final List<Map<String, dynamic>> _testOptions = const [
    {
      'key': 'clock',
      'title': 'Saat Çizimi Testi',
      'iconWidget': Icon(Icons.access_time, size: 32, color: Colors.white),
      'description': 'Görsel-mekansal becerilerinizi test edin.',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC8A2C8), Color(0xFFB190B8)],
      ),
      'emoji': '',
    },
    {
      'key': 'spiral',
      'title': 'Spiral Çizimi Testi',
      'description': 'Akıcılık ve koordinasyonunuzu spiral ile ölçün.',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF9A825), Color(0xFFE19315)],
      ),
      'emoji': '',
    },
    {
      'key': 'meander',
      'title': 'Meander Çizimi Testi',
      'description': 'Karmaşık çizgilerle el-göz koordinasyonunuzu geliştirin.',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFBF7687), Color(0xFFAF6677)],
      ),
      'emoji': '',
    },
    {
      'key': 'handwriting',
      'title': 'El Yazısı Testi',
      'iconWidget': Icon(Icons.edit, size: 32, color: Colors.white),
      'description': 'Doğal el yazınızın akıcılığını ve okunabilirliğini değerlendirin.',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF64AA95), Color(0xFF549A85)],
      ),
      'emoji': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.psychology_outlined,
                    size: 40,
                    color: Color(0xFFE1BEE7),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Yapmak istediğiniz çizim testini seçin',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF757575),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _testOptions.length,
              itemBuilder: (context, index) {
                final test = _testOptions[index];
                Widget iconWidget;
                
                // Handle different icon types
                if (test['key'] == 'spiral') {
                  iconWidget = SvgPicture.asset(
                    'assets/images/spiralCircle.svg',
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  );
                } else if (test['key'] == 'meander') {
                  iconWidget = SvgPicture.asset(
                    'assets/images/spiralSquare.svg',
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  );
                } else {
                  iconWidget = test['iconWidget'] as Widget;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DrawingSelectionCard(
                    title: test['title']!,
                    description: test['description']!,
                    iconWidget: iconWidget,
                    gradient: test['gradient'] as LinearGradient,
                    emoji: test['emoji']!,
                    onTap: () {
                      _handleTestSelection(context, test['key']!, test['title']!);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
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
        return 'Ekrana saat 11\'i 10 geçeyi gösteren bir saat çizin. Saatin tüm öğelerini (sayılar, akrep, yelkovan) eklemeyi unutmayın.';
      case 'spiral':
        return 'Ekranın ortasına, mümkün olduğunca düzgün ve tutarlı bir içe doğru (veya dışa doğru) spiral çizin. Çizgilerinizin birbirine değmemesine ve merkeze doğru düzenli bir şekilde daralmasına dikkat edin. Aşağıdaki spiral örneğini referans alabilirsiniz:';
      case 'meander':
        return 'Ekranın ortasına, birbirine paralel çizgilerden oluşan, köşeli ve düzenli bir kare spiral deseni çizin. Köşelerin keskin ve çizgilerin birbirine yakın ama değmeyen şekilde olmasına özen gösterin. Aşağıdaki kare spiral örneğini referans alabilirsiniz:';
      case 'handwriting':
        return 'Lütfen aşağıdaki cümleyi ekrana okunaklı ve doğal el yazınızla yazın: \nYarın hava güneşli olacak. \nYazınızın boyutu ve eğimi doğal olsun.';
      default:
        return 'Bu test için talimat bulunamadı.';
    }
  }
}

class DrawingSelectionCard extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback onTap;
  final Widget iconWidget;
  final LinearGradient gradient;
  final String emoji;

  const DrawingSelectionCard({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    required this.iconWidget,
    required this.gradient,
    required this.emoji,
  });

  @override
  State<DrawingSelectionCard> createState() => _DrawingSelectionCardState();
}

class _DrawingSelectionCardState extends State<DrawingSelectionCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onTap();
    });
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: widget.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.colors.first.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // İkon alanı
                        Container(
                          width: 68,
                          height: 68,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: widget.iconWidget,
                        ),
                        const SizedBox(width: 16),
                        // Metin alanı
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x40000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Ok işareti
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}