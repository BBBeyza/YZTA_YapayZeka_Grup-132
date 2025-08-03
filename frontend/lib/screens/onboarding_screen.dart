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
  static const Color primaryAccentColor = Color(0xFFFE7950);
  static const Color lightOrangeColor = Color(0xFFFFF0EB);
  static const Color midOrangeColor = Color(0xFFF4B4A1);
  static const Color darkestGradientColor = Color(0xFFE9577A);

  final int _numPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double illustrationSize = screenWidth * 0.6;
    final double cardTopPosition = screenHeight * 0.50;

    // ✨ YENİ: Resmi, üstteki boş alanda (kartın yukarısındaki alanda) dikey olarak ortalamak için hesaplama
    final double imageTopPosition = (cardTopPosition - illustrationSize) / 2;


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
                  lightOrangeColor,
                  midOrangeColor,
                  darkestGradientColor,
                ],
              ),
            ),
          ),

          // 🖼️ ÜSTTEKİ İLLÜSTRASYON GÖRSELİ (Konumu Güncellendi)
          Positioned(
            // ✨ DEĞİŞİKLİK: 'top' değeri artık sabit değil, hesaplanan dinamik değer.
            top: imageTopPosition,
            left: (screenWidth - illustrationSize) / 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(illustrationSize / 2),
              child: SizedBox(
                width: illustrationSize,
                height: illustrationSize,
                child: Image.asset(
                  'assets/images/splash_brain_illustration.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ➡️ SAYFA GEÇİŞLERİ İÇİN PageView ve Buğulu Kart
          Positioned(
            top: cardTopPosition,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                    ),
                    boxShadow: const [
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
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _buildOnboardingPage(
                              context,
                              title: "NeuroGraph'a Hoş Geldiniz",
                              description:
                                  'Beyin sağlığınızı bilimsel temelli testlerle düzenli olarak değerlendirin. NeuroGraph, hafıza, dikkat, problem çözme ve dil akıcılığı gibi kognitif alanlardaki performansınızı ölçmek üzere tasarlandı.',
                              titleColor: primaryAccentColor,
                            ),
                            _buildOnboardingPage(
                              context,
                              title: 'Uygulama Bilgisi',
                              description:
                                  'Uygulamamızdaki testler nöropsikolojik değerlendirme prensiplerine dayanır. Her test, belirli beyin fonksiyonlarını hedefler. Sonuçlarınız, yaş ve eğitim düzeyiniz gibi demografik bilgilerinizle karşılaştırılarak anlamlandırılır.',
                              titleColor: primaryAccentColor,
                            ),
                            _buildOnboardingPage(
                              context,
                              title: 'Test Bilgisi',
                              description:
                                  'Testler bilişsel, çizim ve sesli okuma görevleri içerir. Detaylı raporlar sunulur. Unutmayın, bu uygulama bir teşhis aracı değildir; sağlık şüpheniz varsa profesyonele danışın.',
                              titleColor: primaryAccentColor,
                            ),
                            _buildOnboardingPage(
                              context,
                              title: 'Veri Güvenliği ve Başlangıç',
                              description:
                                  'Verileriniz güvenli şekilde saklanır ve gizlilikle korunur. Sağlıklı bir beyin için ilk adımı atın. Testleri düzenli tamamlayarak gelişiminizi takip edin.',
                              showButton: true,
                              buttonText: 'Devam Et ve Uygulamayı Başlat',
                              titleColor: primaryAccentColor,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0, top: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: List.generate(_numPages, (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  height: 10,
                                  width: _currentPage == index ? 20 : 10,
                                  decoration: BoxDecoration(
                                    color: _currentPage == index
                                        ? primaryAccentColor
                                        : Colors.grey.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                );
                              }),
                            ),
                            _currentPage != _numPages - 1
                                ? TextButton(
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
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 50),
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

  Widget _buildOnboardingPage(
    BuildContext context, {
    required String title,
    required String description,
    bool showButton = false,
    String? buttonText,
    Color? titleColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: titleColor ?? Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          description,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 1),
        if (showButton) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasSeenOnboarding', true);

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccentColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
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
        const Spacer(flex: 2),
      ],
    );
  }
}