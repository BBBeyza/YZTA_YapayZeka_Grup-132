


import 'package:flutter/material.dart';
import 'dart:ui'; // BackdropFilter için gerekli
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences için gerekli
import 'package:neurograph/screens/loginScreen.dart'; // PROJE ADI: neurograph

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Ana renk paleti
  static const Color primaryAccentColor = Color(0xFFFE7950); // Buton ve aktif nokta rengi
  static const Color lightOrangeColor = Color(0xFFFFF0EB); // Arka plan üst gradient rengi
  static const Color midOrangeColor = Color(0xFFF4B4A1); // Arka plan orta gradient rengi
  static const Color darkestGradientColor = Color(0xFFE9577A); // Arka plan alt gradient rengi

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Resmin kaplayacağı boyut
    final double illustrationSize = screenWidth * 0.6; // Görsel boyutu daha da küçültüldü

    // Bilgilendirme kartının başlayacağı yükseklik
    final double cardTopPosition = screenHeight * 0.50; // Kartın konumu eski haline getirildi

    return Scaffold(
      body: Stack(
        children: [
          // 🔴 Arka Plan Gradientsi
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lightOrangeColor, // Açık turuncu
                  midOrangeColor, // Orta turuncu/pembe
                  darkestGradientColor, // Koyu turuncu
                ],
              ),
            ),
          ),
          
          // 🖼️ ÜSTTEKİ İLLÜSTRASYON GÖRSELİ (Daha küçük ve ortalı, tam yuvarlak)
          Positioned(
            top: screenHeight * 0.05, // Resim yukarı çekildi
            left: (screenWidth - illustrationSize) / 2, // Yatayda ortala
            child: ClipRRect( // Resmin yuvarlak bir şekilde kesilmesi için yeni bir ClipRRect
              borderRadius: BorderRadius.circular(illustrationSize / 2),
              child: SizedBox(
                width: illustrationSize,
                height: illustrationSize,
                child: Image.asset(
                  'assets/images/splash_brain_illustration.png', // LÜTFEN KENDİ İLLÜSTRASYON GÖRSEL YOLUNUZU BURAYA YAZIN
                  fit: BoxFit.cover, // Resmi tamamen dolduracak şekilde sığdır
                ),
              ),
            ),
          ),

          // ➡️ SAYFA GEÇİŞLERİ İÇİN PageView ve Buğulu Kart
          Positioned(
            top: cardTopPosition, // Kartın başlama noktası
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30.0), // Kartın üst köşeleri yuvarlak
                topRight: Radius.circular(30.0),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Daha hafif buğulu efekti
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30), // Kartın iç boşluğu
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65), // Kartın rengi hafif saydam beyaz
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                    ),
                    boxShadow: const [ // Hafif bir gölge eklendi
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (int page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          physics: const AlwaysScrollableScrollPhysics(), // Kaydırma sorunlarını gidermek için
                          children: [
                            // Sayfa 1: Giriş ve Kısa Açıklama
                            _buildOnboardingPage(
                              context,
                              title: "NeuroGraph'a Hoş Geldiniz",
                              description:
                                  'Beyin sağlığınızı bilimsel temelli testlerle düzenli olarak değerlendirin. NeuroGraph, hafıza, dikkat, problem çözme ve dil akıcılığı gibi kognitif alanlardaki performansınızı ölçmek üzere tasarlandı.',
                              titleColor: primaryAccentColor, // Başlık rengi turuncumsu/pembe
                            ),
                            // Sayfa 2: Uygulama ve Testler Hakkında Genel Bilgi
                            _buildOnboardingPage(
                              context,
                              title: 'Uygulama ve Test Bilgisi',
                              description:
                                  'Uygulamamızdaki testler nöropsikolojik değerlendirme prensiplerine dayanır. Her test, belirli beyin fonksiyonlarını hedefler. Sonuçlarınız, yaş ve eğitim düzeyiniz gibi demografik bilgilerinizle karşılaştırılarak anlamlandırılır.\n\n'
                                  'Testler: Bilişsel, Çizim ve Sesli Okuma görevleri içerir. Detaylı raporlar sunulur. Unutmayın, bu uygulama bir teşhis aracı değildir; sağlık şüpheniz varsa profesyonele danışın.',
                              titleColor: primaryAccentColor, // Başlık rengi turuncumsu/pembe
                            ),
                            // Sayfa 3: Veri Güvenliği ve Başlangıç Çağrısı
                            _buildOnboardingPage(
                              context,
                              title: 'Veri Güvenliği ve Başlangıç',
                              description:
                                  'Verileriniz güvenli şekilde saklanır ve gizlilikle korunur. Sağlıklı bir beyin için ilk adımı atın. Testleri düzenli tamamlayarak gelişiminizi takip edin.',
                              showButton: true, // Büyük butonu göster
                              buttonText: 'Devam Et ve Uygulamayı Başlat',
                              titleColor: primaryAccentColor, // Başlık rengi turuncumsu/pembe
                            ),
                          ],
                        ),
                      ),
                      // Alt navigasyon barı (indicatorlar ve ileri/skip butonu)
                      // Sadece son sayfada gizlenecek
                      if (_currentPage != 2) // Eğer son sayfada değilsek göster
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Indicator noktaları
                              Row(
                                children: List.generate(3, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                    height: 10,
                                    width: _currentPage == index ? 20 : 10,
                                    decoration: BoxDecoration(
                                      color: _currentPage == index
                                          ? primaryAccentColor // Aktif nokta
                                          : Colors.grey.withOpacity(0.5), // Pasif nokta
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  );
                                }),
                              ),
                              // İleri butonu (son sayfada gizlendiği için burası sadece ilk 2 sayfada görünür)
                              TextButton(
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeIn,
                                  );
                                },
                                child: const Text(
                                  'İleri',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Her bir onboarding sayfası için yardımcı widget
  Widget _buildOnboardingPage(
    BuildContext context, {
    required String title,
    required String description,
    bool showButton = false,
    String? buttonText,
    Color? titleColor, // Başlık rengi için yeni parametre
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Metinleri ortala
      children: [
        // Başlık
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700, // Başlık font kalınlığı ayarlandı
            color: titleColor ?? Colors.black87, // Başlık rengi parametreden alınacak, yoksa siyah
          ),
          textAlign: TextAlign.center, // Metni ortala
        ),
        const SizedBox(height: 15), // Başlık ile açıklama arasına boşluk
        // Açıklama metni
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 15, // Açıklama font boyutu biraz küçültüldü
                color: Colors.black54, // Açıklama rengi siyah karta göre ayarlandı
                height: 1.6, // Satır yüksekliği biraz artırıldı
                fontWeight: FontWeight.w400, // Açıklama font kalınlığı ayarlandı
              ),
              textAlign: TextAlign.center, // Metni ortala
            ),
          ),
        ),
        if (showButton) ...[
          const SizedBox(height: 25), // Metin ile buton arasına boşluk
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Onboarding'i görüldü olarak işaretle
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasSeenOnboarding', true);

                // LoginPage'e yönlendirme
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccentColor, // Buton rengi
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // Yuvarlak köşeler
                ),
              ),
              child: Text(
                buttonText!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

