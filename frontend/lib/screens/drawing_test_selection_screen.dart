import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:neurograph/screens/drawing_test.dart';
import 'tutorial_screen.dart';
import 'package:neurograph/widgets/bottom_navigation_bar.dart';

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
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: const Center(child: Text('Tamamlanm─▒┼ş ├çizimler Ekran─▒')),
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
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 1.0),
        child: AppBar(
          backgroundColor: Color.fromARGB(255, 114, 176, 211),
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          title: Text(
            // Title can change based on the internal tab selected
            _getAppBarTitle(_internalSelectedIndex),
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Color.fromARGB(255, 255, 255, 255),
              height: 1.0,
            ),
          ),
        ),
      ),
      body: _internalWidgetOptions.elementAt(_internalSelectedIndex), // Display internal content
      bottomNavigationBar: BottomNavigationBar( // Your new internal BottomNavigationBar
        currentIndex: _internalSelectedIndex,
        onTap: _onInternalItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.palette_outlined),
            label: 'Test Se├ğ', // Label for the main drawing test selection
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: 'Ge├ğmi┼ş', // Label for completed drawings
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return '├çizim Testleri';
      case 1:
        return 'Tamamlanm─▒┼ş ├çizimler';
      default:
        return '├çizim Testleri';
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
    const {
      'key': 'clock',
      'title': 'Saat ├çizimi Testi',
      'iconWidget': Icon(Icons.access_time, size: 40, color: Color(0xFF72B0D3)),
      'description': 'Zaman─▒ ├ğizerken g├Ârsel-mekansal becerilerinizi test edin.'
    },
    {
      'key': 'spiral',
      'title': 'Spiral ├çizimi Testi',
      'iconWidget': SvgPicture.asset(
          'assets/images/spiralCircle.svg',
          width: 40,
          height: 40,
          colorFilter: const ColorFilter.mode(Color.fromARGB(255, 114, 176, 211), BlendMode.srcIn)
      ),
      'description': 'Ak─▒c─▒l─▒k ve koordinasyonunuzu spiral ile ├Âl├ğ├╝n.'
    },
    {
      'key': 'meander',
      'title': 'Meander ├çizimi Testi',
      'iconWidget': SvgPicture.asset(
          'assets/images/spiralSquare.svg',
          width: 40,
          height: 40,
          colorFilter: const ColorFilter.mode(Color.fromARGB(255, 114, 176, 211), BlendMode.srcIn)
      ),
      'description': 'Karma┼ş─▒k ├ğizgilerle el-g├Âz koordinasyonunuzu geli┼ştirin.'
    },
    const {
      'key': 'handwriting',
      'title': 'El Yaz─▒s─▒ Testi',
      'iconWidget': Icon(Icons.edit, size: 40, color: Color(0xFF72B0D3)),
      'description': 'Do─şal el yaz─▒n─▒z─▒n ak─▒c─▒l─▒─ş─▒n─▒ ve okunabilirli─şini de─şerlendirin.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L├╝tfen yapmak istedi─şiniz ├ğizim testini se├ğin:',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
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
                  iconWidget: test['iconWidget'] as Widget,
                  onTap: () {
                    _handleTestSelection(context, test['key']!, test['title']!);
                  },
                );
              },
            ),
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
        return 'Ekrana saat 11\'i 10 ge├ğeyi g├Âsteren bir saat ├ğizin. Saatin t├╝m ├Â─şelerini (say─▒lar, akrep, yelkovan) eklemeyi unutmay─▒n.';
      case 'spiral':
        return 'Ekran─▒n ortas─▒na, m├╝mk├╝n oldu─şunca d├╝zg├╝n ve tutarl─▒ bir i├ğe do─şru (veya d─▒┼şa do─şru) spiral ├ğizin. ├çizgilerinizin birbirine de─şmemesine ve merkeze do─şru d├╝zenli bir ┼şekilde daralmas─▒na dikkat edin.';
      case 'meander':
        return 'Ekran─▒n ortas─▒na, birbirine paralel ├ğizgilerden olu┼şan, k├Â┼şeli ve d├╝zenli bir "meander" (spiral kare) deseni ├ğizin. K├Â┼şelerin keskin ve ├ğizgilerin birbirine yak─▒n ama de─şmeyen ┼şekilde olmas─▒na ├Âzen g├Âsterin.';
      case 'handwriting':
        return 'L├╝tfen a┼şa─ş─▒daki c├╝mleyi ekrana okunakl─▒ ve do─şal el yaz─▒n─▒zla yaz─▒n: "Yar─▒n hava g├╝ne┼şli olacak." Yaz─▒n─▒z─▒n boyutu ve e─şimi do─şal olsun.';
      default:
        return 'Bu test i├ğin talimat bulunamad─▒.';
    }
  }
}


class DrawingSelectionCard extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final Widget iconWidget;

  const DrawingSelectionCard({
    super.key,
    required this.title,
    required this.onTap,
    required this.iconWidget,
  });

  @override
  State<DrawingSelectionCard> createState() => _DrawingSelectionCardState();
}

class _DrawingSelectionCardState extends State<DrawingSelectionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          color: Colors.white,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: widget.iconWidget,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
