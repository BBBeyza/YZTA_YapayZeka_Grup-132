import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurograph/widgets/modern_bottom_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cognitive_test.dart';
import 'drawing_test_selection_screen.dart';
import 'audio_test_screen.dart';
import 'user_profile.dart';
import 'chatbot_screen.dart';
import 'reports_screen.dart';

// Ana navigasyonu yöneten HomeScreen widget'ı
class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String userName = "Kullanıcı";
  double progressValue = 0.0;
  String progressText = '0/0 test tamamlandı';

  // Düzeltme: Alt navigasyon çubuğundaki ekranları içeren liste.
  // Her ekran kendi dosyasından içe aktarılmıştır.
  static const List<Widget> _widgetOptions = <Widget>[
    _HomeContent(), // Ana ekranın içeriği
    GeminiChatScreen(),
    ReportsScreen(),
    UserProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _selectedIndex = widget.initialTabIndex;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() {
        userName = user.displayName ?? user.email?.split('@').first ?? "Kullanıcı";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Arka planı geri beyaz yap
      extendBody: true,
      body: Column(
        children: [
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          ModernBottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}

// Ana ekran içeriğini barındıran widget
// Düzeltme: `_HomeContent` bir `StatelessWidget` olarak ayarlandı
class _HomeContent extends StatelessWidget {
  const _HomeContent({super.key});

  // `_HomeContent` içinde veri yükleme işlemi olmadığı için
  // `userName`, `progressValue` ve `progressText` değerlerini
  // `HomeScreen`'den almalıyız.
  // Ancak, bu kod parçacığında _HomeContent'e bu değerleri aktarmadığınız için
  // şimdilik varsayılan değerleri kullanmaya devam edeceğim.
  // Daha sonra bu değerleri `_HomeScreenState` içindeki değişkenlerle güncelleyebilirsiniz.
  final String userName = "Kullanıcı";
  final double progressValue = 0.0;
  final String progressText = '0/0 test tamamlandı';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: _HomeScreenClipper(),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFE1BEE7).withOpacity(0.6),
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 10),
                  _buildAppBar(context),
                  const SizedBox(height: 30),
                  _buildGreetingSection(context),
                  const SizedBox(height: 30),
                  _buildProgressSection(context),
                  const SizedBox(height: 32),
                  _buildTestStatusSection(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Image.asset(
          'assets/images/logo.png',
          height: 40,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NeuroGraph',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.0,
                ),
          ),
          Text(
            'Beyin sağlığınızı keşfedin',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                  height: 1.0,
                ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 30.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 20,
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingSection(BuildContext context) {
    return Text(
      'Hoşgeldin, $userName',
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test ilerlemen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey.shade300,
            color: Theme.of(context).colorScheme.primary,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          Text(
            progressText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Durumun',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.75,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CognitiveTestScreen(),
                  ),
                );
              },
              child: const _TestCard(
                imagePath: 'assets/images/bilissel_test.jpeg',
                title: 'Bilişsel Test',
                description: 'Hafıza & dikkat becerilerini ölç',
                cardColor: Colors.white,
                barColor: Color(0xFFC8A2C8),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DrawingTestSelectionScreen(),
                  ),
                );
              },
              child: const _TestCard(
                imagePath: 'assets/images/cizim_testi.jpeg',
                title: 'Çizim Testi',
                description: 'Görsel-motor yeteneklerini test et',
                cardColor: Colors.white,
                barColor: Color(0xFFF9A825),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReadingTestScreen(),
                  ),
                );
              },
              child: const _TestCard(
                imagePath: 'assets/images/sesli_okuma.jpeg',
                title: 'Sesli Okuma Testi',
                description: 'Okuma akıcılığı ve anlama becerileri',
                cardColor: Colors.white,
                barColor: Color(0xFFBF7687),
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Geçmiş Raporlar Görüntülenecek'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const _TestCard(
                imagePath: 'assets/images/gecmis_raporlar.jpeg',
                title: 'Geçmiş Raporlar',
                description: 'Tüm test geçmişin burada',
                cardColor: Colors.white,
                barColor: Color(0xFF64AA95),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Alt navigasyon çubuğu widget'ları
class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color selectedItemColor;
  final Color unselectedItemColor;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.selectedItemColor,
    required this.unselectedItemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 0,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(context, Icons.home_outlined, 'Anasayfa', 0),
          _buildNavBarItem(context, Icons.bar_chart_outlined, 'Gemini Chat', 1),
          _buildNavBarItem(context, Icons.notifications_none_outlined, 'Raporlar', 2),
          _buildNavBarItem(context, Icons.person_outline, 'Profil', 3),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: isSelected
                ? BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            child: Icon(
              icon,
              color: isSelected ? selectedItemColor : unselectedItemColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedItemColor : unselectedItemColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Her bir test kartı için özelleştirilmiş Widget
class _TestCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final Color cardColor;
  final Color barColor;

  const _TestCard({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.cardColor,
    required this.barColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Özel Clipper Sınıfı - Mor arka plan için daha oval bir kavis oluşturur
class _HomeScreenClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
