import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cognitive_test.dart';
import 'drawing_test.dart';
import 'audio_test_screen.dart';
import 'user_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardsAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _cardsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutExpo),
      ),
    );

    _controller.forward();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.13, // Slogan sığsın
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF9FAFB), Color(0xFFE5E7EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF000000),
                    blurRadius: 10,
                    spreadRadius: -5,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.06,
                    screenHeight * 0.01,
                    screenWidth * 0.06,
                    screenHeight * 0.02, // Aşağı kaydırma için artırıldı
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FadeTransition(
                        opacity: _headerAnimation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, -0.4),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _controller,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                height: screenWidth * 0.12,
                                width: screenWidth * 0.12,
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NeuroGraph',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: const Color(0xFF72B0D3),
                                          fontWeight: FontWeight.w800,
                                          fontSize: screenWidth * 0.06,
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                  Text(
                                    'Beyin sağlığınızı keşfedin',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF6B7280),
                                          fontWeight: FontWeight.w500,
                                          fontSize: screenWidth * 0.035,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserProfileScreen(),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'profile_picture',
                          child: CircleAvatar(
                            radius: screenWidth * 0.06,
                            backgroundImage: const AssetImage(
                              'assets/images/profile.png',
                            ),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical:
                        screenHeight * 0.01, // Aşağı kaydırma için artırıldı
                  ),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.045),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF0F4F8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _headerAnimation,
                          child: Text(
                            'Hoşgeldin Emin,',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: const Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: screenWidth * 0.04,
                                  letterSpacing: -0.2,
                                ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Test İlerlemen',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E3A8A),
                                fontSize: screenWidth * 0.04,
                              ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        LinearProgressIndicator(
                          value: 0.66,
                          backgroundColor: const Color(0xFFDDE5F0),
                          color: const Color(0xFF72B0D3),
                          minHeight: screenHeight * 0.01,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Bu hafta 2/3 testi tamamladın!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF6B7280),
                                fontSize: screenWidth * 0.03,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical:
                          screenHeight * 0.02, // Aşağı kaydırma için artırıldı
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: screenWidth * 0.03,
                      mainAxisSpacing: screenHeight * 0.015,
                      childAspectRatio: 0.7,
                      children: [
                        ModernTestCard(
                          icon: Icons.psychology_outlined,
                          title: 'Bilişsel Test',
                          description: 'Hafıza ve dikkat becerilerinizi ölçün.',
                          score: 'Son Skor: 85%',
                          date: 'Son Çözüm: 23 Temmuz 2025',
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
                        ModernTestCard(
                          icon: Icons.edit_outlined,
                          title: 'Çizim Testleri',
                          description:
                              'Görsel-motor yeteneklerinizi test edin.',
                          score: 'Son Skor: 92%',
                          date: 'Son Çözüm: 22 Temmuz 2025',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DrawingTestScreen(),
                              ),
                            );
                          },
                        ),
                        ModernTestCard(
                          icon: Icons.volume_up_outlined,
                          title: 'Sesli Okuma',
                          description: 'Okuma akıcılığı ve anlama becerileri.',
                          score: 'Son Skor: 78%',
                          date: 'Son Çözüm: 21 Temmuz 2025',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReadingTestScreen(),
                              ),
                            );
                          },
                        ),
                        ModernTestCard(
                          icon: Icons.history_edu_outlined,
                          title: 'Geçmiş Raporlar',
                          description: 'Önceki test sonuçlarınızı inceleyin.',
                          score: '',
                          date: 'Son Rapor: 20 Temmuz 2025',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Geçmiş Raporlar (Yakında!)',
                                ),
                                backgroundColor: const Color(0xFF72B0D3),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.02), // Daraltıldı
                  child: Text(
                    'NeuroGraph v1.0 - Beyin sağlığınızı sürekli takip edin.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: screenWidth * 0.025,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
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

class ModernTestCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String score;
  final String date;
  final VoidCallback onTap;

  const ModernTestCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.score,
    required this.date,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F4F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 5),
              // elevation etkisi için shadow artırıldı
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: const BoxDecoration(
                color: Color(0xFFDDE5F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: screenWidth * 0.09,
                color: const Color(0xFF72B0D3),
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E3A8A),
                fontSize: screenWidth * 0.05,
              ),
            ),
            SizedBox(height: screenWidth * 0.015),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: screenWidth * 0.03,
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.015),
            Text(
              score,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.03,
              ),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              date,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
                fontSize: screenWidth * 0.025,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
