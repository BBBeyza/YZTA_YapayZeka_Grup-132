// lib/screens/loginScreen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neurograph/screens/onboarding_screen.dart'; // PROJE ADI: neurograph
import 'package:neurograph/screens/homePage.dart';
import 'package:neurograph/screens/registerScreen.dart'; // RegisterScreen'i import ettik.
import 'package:neurograph/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? hasSeenOnboarding = prefs.getBool('hasSeenOnboarding');

    // Eğer onboarding görülmediyse veya null ise onboarding ekranına yönlendir
    if (hasSeenOnboarding == null || !hasSeenOnboarding) {
      if (mounted) {
        // Onboarding'e yönlendirirken, geri tuşuyla tekrar geri dönülmemesi için pushReplacement kullan
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  void _login() async {
    if (!mounted) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Validasyon kontrolleri
      if (_emailController.text.isEmpty) {
        throw 'E-posta alanı boş bırakılamaz';
      }

      if (!_emailController.text.contains('@')) {
        throw 'Geçerli bir e-posta adresi girin';
      }

      if (_passwordController.text.isEmpty) {
        throw 'Şifre alanı boş bırakılamaz';
      }

      // Firebase giriş işlemi
      User? user = await _auth.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        // Onboarding'i gördük olarak işaretle (eğer zaten işaretli değilse)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);

        if (!mounted) return;
        // Giriş başarılı, ana sayfaya yönlendir ve geri dönülmesini engelle
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getFirebaseErrorMessage(e));
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'invalid-email':
        return 'Geçersiz e-posta formatı';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'too-many-requests':
        return 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin';
      case 'operation-not-allowed':
        return 'E-posta/şifre ile giriş devre dışı';
      default:
        return 'Giriş sırasında hata oluştu: ${e.message}';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // LoginPage'in kendisi bir Scaffold döndürüyor, bu Material context sorununu çözecektir.
    return Scaffold(
      // extendBodyBehindAppBar: true, // Bu satırı kaldırdık, çünkü AppBar kullanmıyoruz ve gereksiz olabilir.
      body: Container( // Bu Container Scaffold'un body'si oldu
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8), // Ana turuncu
              Theme.of(context).colorScheme.secondary.withOpacity(0.8), // İkincil turuncu
              Theme.of(context).colorScheme.tertiary.withOpacity(0.8), // Üçüncül turuncu
              Theme.of(context).colorScheme.primary.withOpacity(0.9), // Daha koyu bir turuncu
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // Tema yüzey rengi (genellikle beyaz)
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Gölgeyi biraz yumuşattık
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logowt.png', // Logo görselinin doğru yolu
                    height: 100, // Logo boyutu ayarlandı
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hoş Geldiniz!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface, // Tema yüzey üzerindeki metin rengi
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'NeuroGraph',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary, // Tema ana rengi (turuncu)
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // Hata Mesajı
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 20),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            fillColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Theme.of(context).colorScheme.onSurfaceVariant;
                            }),
                            checkColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          Text(
                            'Beni Hatırla',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Şifre sıfırlama (Yakında!)',
                              ),
                            ),
                          );
                        },
                        child: const Text('Şifremi Unuttum?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Text('Giriş Yap'),
                        ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Hesabın yok mu? Kayıt Ol'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}