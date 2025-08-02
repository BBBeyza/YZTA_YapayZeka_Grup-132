import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:neurograph/screens/drawing_test.dart';
import 'tutorial_screen.dart';
import 'package:neurograph/widgets/modern_bottom_navigation_bar.dart';

// Assuming these are separate screens within the DrawingTest flow,
// or placeholder for other content when this tab is selected.
// For demonstration, these are simplified.
class DrawingTestHomeContent extends StatelessWidget {
  const DrawingTestHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the content for the 'Drawing Tests' tab's default view
    // It will contain your GridView.builder for test selections
    return _DrawingTestSelectionScreenContent(); // Use the existing content logic
  }
}

class CompletedDrawingsScreen extends StatelessWidget {
  const CompletedDrawingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette,
              size: 80,
              color: Color(0xFFE1BEE7),
            ),
            SizedBox(height: 16),
            Text(
              'Tamamlanmış Çizimler',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A1B9A),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Henüz tamamlanmış çizim bulunmuyor',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawingTestSelectionScreen extends StatefulWidget {
  // initialTabIndex is no longer needed here if HomePage manages the main tabs
  const DrawingTestSelectionScreen({super.key});

  @override
  State<DrawingTestSelectionScreen> createState() => _DrawingTestSelectionScreenState();
}

class _DrawingTestSelectionScreenState extends State<DrawingTestSelectionScreen> {
  // This _selectedIndex now manages the internal tabs of DrawingTestSelectionScreen
  int _internalSelectedIndex = 0;

  // These are the screens for the internal bottom navigation bar of DrawingTestSelectionScreen
  static const List<Widget> _internalWidgetOptions = <Widget>[
    DrawingTestHomeContent(),    // Represents the main selection grid for drawing tests
    CompletedDrawingsScreen(), // Example: A screen for viewing past drawings
  ];

  void _onInternalItemTapped(int index) {
    setState(() {
      _internalSelectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle is usually set once at the app's root
    // or by the main HomePage, so it's often not needed here.
  }

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
            title: Text(
              _getAppBarTitle(_internalSelectedIndex),
              style: const TextStyle(
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
        child: _internalWidgetOptions.elementAt(_internalSelectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _internalSelectedIndex,
            onTap: _onInternalItemTapped,
            selectedItemColor: const Color(0xFF6A1B9A),
            unselectedItemColor: const Color(0xFFBDBDBD),
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.palette_outlined),
                activeIcon: Icon(Icons.palette),
                label: 'Testler',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Geçmiş',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return '🎨 Çizim Testleri';
      case 1:
        return '📋 Tamamlanmış Çizimler';
      default:
        return '🎨 Çizim Testleri';
    }
  }
}

// Extracting the content of DrawingTestSelectionScreen into a separate stateless widget
// so it can be used as one of the _internalWidgetOptions
class _DrawingTestSelectionScreenContent extends StatelessWidget {
  _DrawingTestSelectionScreenContent({super.key});

  static const String _meanderTutorialVideoUrl = 'assets/videos/MeanderTutorialVideo.mp4';
  static const String _spiralTutorialVideoUrl = 'assets/videos/SpiralTutorialVideo.mp4';

  final List<Map<String, dynamic>> _testOptions = [
    {
      'key': 'clock',
      'title': 'Saat Çizimi Testi',
      'iconWidget': const Icon(Icons.access_time, size: 32, color: Colors.white),
      'description': 'Görsel-mekansal becerilerinizi test edin.',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC8A2C8), Color(0xFFB190B8)],
      ),
      'emoji': '',
    },
    {
      'key': 'spiral',
      'title': 'Spiral Çizimi Testi',
      'iconWidget': SvgPicture.asset(
          'assets/images/spiralCircle.svg',
          width: 32,
          height: 32,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
      ),
      'description': 'Akıcılık ve koordinasyonunuzu spiral ile ölçün.',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF9A825), Color(0xFFE19315)],
      ),
      'emoji': '',
    },
    {
      'key': 'meander',
      'title': 'Meander Çizimi Testi',
      'iconWidget': SvgPicture.asset(
          'assets/images/spiralSquare.svg',
          width: 32,
          height: 32,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
      ),
      'description': 'Karmaşık çizgilerle el-göz koordinasyonunuzu geliştirin.',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFBF7687), Color(0xFFAF6677)],
      ),
      'emoji': '',
    },
    {
      'key': 'handwriting',
      'title': 'El Yazısı Testi',
      'iconWidget': const Icon(Icons.edit, size: 32, color: Colors.white),
      'description': 'Doğal el yazınızın akıcılığını ve okunabilirliğini değerlendirin.',
      'gradient': const LinearGradient(
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DrawingSelectionCard(
                    title: test['title']!,
                    description: test['description']!,
                    iconWidget: test['iconWidget'] as Widget,
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