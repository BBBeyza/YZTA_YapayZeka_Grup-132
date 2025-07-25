import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Test Ekranı Importları
import 'cognitive_test.dart'; // Bilişsel Test Ekranı
import 'drawing_test_selection_screen.dart'; // Çizim Testleri Ekranı
import 'audio_test_screen.dart'; // Audio Test Ekranı (Eğer düzeltildiyse ve kullanılacaksa)
import 'user_profile.dart'; // Profil Ekranı (Eğer bağlanacaksa)
// import 'loginScreen.dart'; // Eğer buraya bir yönlendirme yapılacaksa
// import 'onboarding_screen.dart'; // Eğer buraya bir yönlendirme yapılacaksa


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // BottomNavigationBar için seçili index

  // bottom navigation bar'daki ikonlara tıklanınca açılacak sayfalar listesi
  static const List<Widget> _widgetOptions = <Widget>[
    HomeContent(), // Anasayfa içeriği
    Text('Gemini Chat Screen (Placeholder)'), // Gemini Chat ekranı
    Text('Reports Screen (Placeholder)'), // Raporlar ekranı
    UserProfileScreen(), // Profil ekranı
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: _widgetOptions.elementAt(_selectedIndex), // Seçili indexe göre sayfayı göster
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Gemini Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'Raporlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width; // Artık doğrudan kullanılmıyor ama kalsın
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NeuroGraph',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Beyin sağlığınızı keşfedin',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 20,
                  // profile.png asset'ini projenize eklediğinizden emin olun
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoşgeldin, Emin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Test İlerlemen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.66,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF72B0D3),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Bu hafta 2/3 testi tamamladın!'
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Test Durumun',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildTestCard(
                  context,
                  icon: Icons.psychology_outlined,
                  title: 'Bilişsel Test',
                  score: 'Son Skor: 85%',
                  description: 'Hafıza & dikkat becerilerini ölç',
                  onTap: () { // BİLİŞSEL TESTİ BAĞLADIK
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CognitiveTestScreen(),
                      ),
                    );
                  },
                ),
                _buildTestCard(
                  context,
                  icon: Icons.edit_outlined,
                  title: 'Çizim Testleri',
                  score: 'Son Skor: 92%',
                  description: 'Görsel-motor yeteneklerini test et',
                  onTap: () { // ÇİZİM TESTİNİ BAĞLADIK
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DrawingTestSelectionScreen(),
                      ),
                    );
                  },
                ),
                _buildTestCard(
                  context,
                  icon: Icons.volume_up_outlined,
                  title: 'Sesli Okuma',
                  score: 'Son Skor: 78%',
                  description: 'Okuma akıcılığı ve anlama becerileri',
                  onTap: () {
                    // AudioTestScreen'ınız hala hatalıysa, bu kısmı yorum satırı yapın
                    // veya önceki gibi bir SnackBar gösterin.
                    // Eğer düzelttiyseniz, aşağıdaki kodu kullanın:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReadingTestScreen(), // AUDIO TESTİ BAĞLADIK
                      ),
                    );
                    // Geçici SnackBar, eğer AudioTestScreen'ı henüz düzeltmediyseniz
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: const Text(
                    //       'Sesli Okuma Testi Yakında!',
                    //     ),
                    //     backgroundColor: Theme.of(context).colorScheme.primary,
                    //     duration: const Duration(seconds: 2),
                    //   ),
                    // );
                  },
                ),
                _buildTestCard(
                  context,
                  icon: Icons.history_edu_outlined,
                  title: 'Geçmiş Raporlar',
                  score: 'Son Rapor: 20 Temmuz 2025',
                  description: 'Tüm test geçmişin burada',
                  onTap: () {
                    // Şu an için sadece bir SnackBar gösteriyoruz, raporlar ekranı yoksa
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Geçmiş Raporlar Görüntülenecek (Yakında!)',
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    // Eğer ReportsScreen adında bir ekranınız varsa, şöyle bağlayabilirsiniz:
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const ReportsScreen(),
                    //   ),
                    // );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // _buildTestCard metoduna onTap parametresi eklendi
  Widget _buildTestCard(BuildContext context,
      {required IconData icon,
        required String title,
        required String score,
        required String description,
        required VoidCallback onTap // <-- BURASI EKLENDİ
      }) {
    // Kartın genişliği ekran genişliğinin yarısı - boşluklar olarak ayarlanmış
    final cardWidth = MediaQuery.of(context).size.width / 2 - 24;
    // Sabit bir yükseklik belirledik. Bu değeri, tüm kart içeriğini rahatça sığdıracak şekilde ayarlamanız gerekebilir.
    const double cardHeight = 180.0; // Deneyerek optimize edin (ör: 180, 200, 220)

    return GestureDetector( // <-- Kartı tıklanabilir yapmak için GestureDetector eklendi
      onTap: onTap, // <-- onTap callback'i kullanıldı
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFDDE5F0),
              child: Icon(icon, color: const Color(0xFF72B0D3)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              score,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}