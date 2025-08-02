import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurograph/widgets/bottom_navigation_bar.dart';
import 'cognitive_test.dart';
import 'drawing_test_selection_screen.dart';
import 'audio_test_screen.dart';
import 'user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile.dart';

// GeminiChatScreen ve ReportsScreen widget'ları eksiksiz.
class GeminiChatScreen extends StatelessWidget {
  const GeminiChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini Chat')),
      body: const Center(child: Text('Gemini Chat Ekranı')),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: const Center(child: Text('Raporlar Ekranı')),
    );
  }
}

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

  // Düzeltme: _widgetOptions listesindeki HomeScreen()'i kaldırdım
  // ve yerine bu widget'ın kendisini temsil eden bir widget (mesela Text('Anasayfa')) kullandım.
  // Bu sayede sonsuz döngüye girmesi engellendi.
  static const List<Widget> _widgetOptions = <Widget>[
    _HomeContent(), // Burası artık Home ekranının içeriği olacak
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
        userName =
            user.displayName ?? user.email?.split('@').first ?? "Kullanıcı";
      });
    }
  }

  // Artık sadece ana ekran içeriğini dönen bir widget oluşturuyoruz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// Yeni bir _HomeContent widget'ı oluşturarak önceki HomeScreen'in içeriğini buraya taşıdık.
// Bu, _widgetOptions listesinde HomeScreen'in kendisini kullanma hatasını giderir.
class _HomeContent extends StatefulWidget {
  const _HomeContent({super.key});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String userName = "Kullanıcı";
  double progressValue = 0.0;
  String progressText = '0/0 test tamamlandı';

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        userName =
            user.displayName ?? user.email?.split('@').first ?? "Kullanıcı";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Arka Plan Şekli - Oval kısmı ClipPath ile daha belirgin hale getirildi
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: _HomeScreenClipper(),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.purple.shade100.withOpacity(0.6),
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

  // Üst Uygulama Çubuğu (AppBar)
  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false, // Geri butonunu kaldır
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
              // Profil sayfasına yönlendirme
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

  // Selamlama Bölümü
  Widget _buildGreetingSection(BuildContext context) {
    return Text(
      'Hoşgeldin, $userName', // Kullanıcının adı dinamik olarak eklendi
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
    );
  }

  // Test İlerleme Bölümü
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
            progressText, // İlerleme metni dinamik hale getirildi
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }

  // Test Durumları Bölümü
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
                barColor: Color.fromARGB(255, 191, 118, 135),
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
                barColor: Color.fromARGB(255, 100, 170, 149),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Alt Navigasyon Çubuğu widget'ı
Widget _buildBottomNavBar(BuildContext context, int selectedIndex, Function(int) onItemTapped) {
  return Container(
    height: 90, // Navigasyon çubuğu yüksekliği ayarlandı
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
        _buildNavBarItem(context, Icons.home_outlined, 'Anasayfa', 0, selectedIndex, onItemTapped),
        _buildNavBarItem(context, Icons.bar_chart_outlined, 'Gemini Chat', 1, selectedIndex, onItemTapped),
        _buildNavBarItem(context, Icons.notifications_none_outlined, 'Raporlar', 2, selectedIndex, onItemTapped),
        _buildNavBarItem(context, Icons.person_outline, 'Profil', 3, selectedIndex, onItemTapped),
      ],
    ),
  );
}

// Alt navigasyon çubuğu için tekil eleman widget'ı
Widget _buildNavBarItem(BuildContext context, IconData icon, String label, int index, int selectedIndex, Function(int) onItemTapped) {
  final isSelected = index == selectedIndex;
  return GestureDetector(
    onTap: () => onItemTapped(index),
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
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
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
    path.lineTo(0, size.height - 50); // Sol alt nokta
    // Sol alttan sağ alta doğru daha büyük ve yumuşak bir kavis çizilir
    path.quadraticBezierTo(
      size.width / 2, // Kontrol noktası, yatayda tam ortada
      size.height, // Kontrol noktası, dikeyde en altta
      size.width, // Bitiş noktası, sağ alt köşe
      size.height - 50, // Bitiş noktası, dikeyde biraz yukarıda
    );
    path.lineTo(size.width, 0); // Sağ üst köşe
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
