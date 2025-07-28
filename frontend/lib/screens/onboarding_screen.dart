import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Bu satırın eklendiğinden emin olun
import 'loginScreen.dart';

// Onboarding metnini widget dışına taşı
const String onboardingText = '''
NeuroGraph'a Hoş Geldiniz
Bu uygulama, beyin sağlığınızı çeşitli bilimsel temelli testlerle düzenli olarak değerlendirmenize olanak tanır. NeuroGraph, hafıza, dikkat, problem çözme, görsel-motor beceriler ve dil akıcılığı gibi kognitif alanlardaki performansınızı ölçmek üzere tasarlanmıştır. Uygulamamızda sunulan testler, nöropsikolojik değerlendirme prensiplerine dayanmaktadır. Her test, belirli beyin fonksiyonlarını hedef alır ve sonuçlarınız, yaş ve eğitim düzeyi gibi demografik bilgilerinize göre normalize edilmiş verilerle karşılaştırılarak anlamlandırılır.

Testler Hakkında:
- Bilişsel Testler: Hafıza, dikkat, yürütücü işlevler (planlama, karar verme), ve işlemleme hızınızı değerlendiren çeşitli görevler içerir. Bu testler, zaman içindeki kognitif performans değişikliklerini izlemenize yardımcı olabilir.
- Çizim Testleri: Görsel-motor koordinasyonunuzu, el becerilerinizi ve uzamsal algınızı ölçmek için tasarlanmıştır. Belirli şekilleri kopyalama veya çizme görevlerini içerir.
- Sesli Okuma Testi: Dil akıcılığınızı, okuma hızınızı ve telaffuz doğruluğunuzu değerlendirir. Belirli metinleri okumanız ve seslendirmeniz istenir.

Tamamladığınız her testin ardından, performansınızı gösteren detaylı bir rapor sunulur. Bu raporlar, zaman içindeki ilerlemenizi takip etmenize ve potansiyel değişiklikleri gözlemlemenize yardımcı olur. Unutmayın ki bu uygulama bir teşhis aracı değildir ve herhangi bir sağlık sorununuz olduğundan şüpheleniyorsanız bir sağlık profesyoneline danışmanız önemlidir.

Verilerinizin gizliliği ve güvenliği bizim için en öncelikli konudur. Topladığımız veriler, yalnızca performansınızı değerlendirmek ve size kişiselleştirilmiş geri bildirim sunmak amacıyla kullanılır. Kişisel bilgileriniz güvenli bir şekilde saklanır ve üçüncü şahıslarla paylaşılmaz. Detaylı bilgi için lütfen Gizlilik Politikamızı inceleyin.

Sağlıklı bir beyin için ilk adımı atın. Uygulamamızdaki testleri düzenli olarak tamamlayarak kognitif sağlığınız hakkında daha fazla bilgi edinin ve zaman içindeki değişimleri takip edin.

Devam etmek için lütfen aşağıdaki butona tıklayın.
''';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NeuroGraph Bilgilendirme',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 20, 175),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _LogoWidget(),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  onboardingText,
                  textAlign: TextAlign.justify,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _ContinueButton(onContinue: () {
                _setOnboardingAsSeen(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _setOnboardingAsSeen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }
}

class _LogoWidget extends StatelessWidget {
  const _LogoWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        height: 120,
        width: 120,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onContinue;
  const _ContinueButton({required this.onContinue, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onContinue,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      child: const Text(
        'Devam Et ve Uygulamayı Başlat',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
