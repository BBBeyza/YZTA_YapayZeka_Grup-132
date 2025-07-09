import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome için
import 'cognitive_test.dart'; // Bilişsel test ekranı
import 'drawing_test.dart'; // Çizim test ekranı
import 'audio_test_screen.dart'; // Sesli okuma test ekranı (veya sizin ReadingTestScreen'iniz)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headerAnimation; // Logo ve başlık animasyonu
  late Animation<double> _cardsAnimation; // Kartların toplu animasyonu

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Genel animasyon süresi
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.6,
          curve: Curves.easeOutCubic,
        ), // Başlık kısmı daha hızlı görünsün
      ),
    );

    _cardsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.4,
          1.0,
          curve: Curves.easeOutBack,
        ), // Kartlar biraz gecikmeli ve yaylı görünsün
      ),
    );

    _controller.forward(); // Animasyonu bir kez başlat

    // Bildirim çubuğunu şeffaf yapar ve ikonları açık renkli gösterir
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // AppBar'ın arkasındaki arka planın görünmesini sağlar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Şeffaf AppBar
        elevation: 0, // Gölge yok
        toolbarHeight:
            0, // AppBar'ın kendi yüksekliğini sıfırla, böylece custom header tam kontrol sağlar
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(
              'assets/images/backgroundN.png',
            ), // Arka plan görseli
            fit: BoxFit.cover,
            // Eğer arka plan görseli üzerinde hafif bir karartma istiyorsanız bunu kullanabilirsiniz.
            // Aksi takdirde tamamen kaldırın.
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4), // Arka planı biraz karart
              BlendMode.darken,
            ),
          ),
          // gradient özelliği kaldırıldı, çünkü image ile çakışıyordu.
          // Eğer hem resim hem de gradient aynı anda görünmesini isterseniz,
          // Box Decoration yerine Stack kullanarak katmanlar oluşturmanız gerekir.
        ),
        child: SafeArea(
          // Güvenli alan: bildirim çubuğu ve navigasyon çubuğu altını kapsar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo ve Başlık Bölümü (Sol Üst Köşe)
              FadeTransition(
                opacity: _headerAnimation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(-0.5, 0), // Soldan kaydırarak getir
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOutQuad,
                        ),
                      ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      24.0,
                      20.0,
                      24.0,
                      30.0,
                    ), // Sol, üst, sağ, alt boşluk
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Sola hizala
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        Image.asset(
                          'assets/images/logo.png', // Logo dosya yolu
                          height: 70, // Logo boyutu
                          width: 70,
                        ),
                        const SizedBox(
                          width: 15,
                        ), // Logo ile yazı arasında boşluk
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NeuroGraph',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color:
                                        Colors.white, // Metin rengi beyaz olsun
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28, // Başlık boyutunu ayarla
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Beyin sağlığınızı keşfedin.', // Bilgilendirici yazı
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors
                                        .white70, // Metin rengi hafif opak beyaz
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Ana İçerik (Test Kartları)
              Expanded(
                // Kalan alanı kaplaması için Expanded
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: AnimatedBuilder(
                      animation: _cardsAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          // Kartların hepsini birden animasyonla getir
                          scale: _cardsAnimation.value,
                          child: Opacity(
                            opacity: _cardsAnimation.value.clamp(0.0, 1.0),
                            child: GridView.count(
                              shrinkWrap:
                                  true, // İçeriğe göre yüksekliği ayarla
                              physics:
                                  const NeverScrollableScrollPhysics(), // Kaydırmayı devre dışı bırak
                              crossAxisCount: 2, // 2 sütun
                              crossAxisSpacing: 20.0, // Yatay boşluk
                              mainAxisSpacing: 20.0, // Dikey boşluk
                              childAspectRatio:
                                  1.0, // Kare kartlar için 1.0, dikdörtgen için artırılabilir
                              children: [
                                TestCard(
                                  icon: Icons.psychology_outlined,
                                  title: 'Bilişsel Test',
                                  description: 'Hafıza ve dikkat becerileri.',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CognitiveTestScreen(),
                                      ),
                                    );
                                  },
                                ),
                                TestCard(
                                  icon: Icons.edit_outlined,
                                  title: 'Çizim Testleri',
                                  description: 'Görsel-motor ve el yazısı.',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DrawingTestScreen(),
                                      ),
                                    );
                                  },
                                ),
                                TestCard(
                                  icon: Icons.volume_up_outlined,
                                  title: 'Sesli Okuma',
                                  description: 'Okuma akıcılığı ve anlama.',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ReadingTestScreen(),
                                      ),
                                    );
                                  },
                                ),
                                TestCard(
                                  icon: Icons.history_edu_outlined,
                                  title: 'Geçmiş Raporlar',
                                  description: 'Önceki test sonuçlarını gör.',
                                  onTap: () {
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
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Test kartı için ayrı bir widget
class TestCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const TestCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceVariant,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
