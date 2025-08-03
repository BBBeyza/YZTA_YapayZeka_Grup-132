import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/loginScreen.dart';
import 'screens/homePage.dart';
import 'services/auth_service.dart';
import 'dart:async';

Future<void> main() async {
  // Flutter engine ile iletişim için gerekli
  WidgetsFlutterBinding.ensureInitialized();

  // Çoklu başlatmayı engellemek için runZonedGuarded kullanıyoruz
  await runZonedGuarded(
    () async {
      // Çevresel değişkenleri yükle
      await _loadEnvironmentVariables();

      // Firebase'i güvenli şekilde başlat
      await _initializeFirebase();

      // Uygulamayı başlat
      runApp(const MyApp());
    },
    (error, stack) {
      print('Global error caught: $error');
      print(stack);
    },
  );
}

Future<void> _loadEnvironmentVariables() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Dotenv yükleme hatası: $e');
  }
}

Future<void> _initializeFirebase() async {
  try {
    // Firebase uygulamalar listesini kontrol et
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase başarıyla başlatıldı');

      // Firebase başlatma sonrası ek ayarlar
      await _configureFirebaseSettings();
    }
  } catch (e) {
    print('Firebase başlatma hatası: $e');
    // Firebase başlatılamazsa uygulama çalışmaya devam etsin
  }
}

Future<void> _configureFirebaseSettings() async {
  // Firebase Auth ayarları
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  // Firebase performans ayarları (isteğe bağlı)
  // await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroGraph',
      debugShowCheckedModeBanner: false,
      theme: _buildThemeData(context),
      builder: (context, child) {
        // Sistem UI ayarları
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        );
        return child!;
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  late Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _initializeAuthStream();
  }

  void _initializeAuthStream() {
    try {
      _authStream = _authService.user;
    } catch (e) {
      print('Auth stream başlatma hatası: $e');
      // Hata durumunda boş bir stream oluştur
      _authStream = Stream.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        // Veri yükleniyor durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE1BEE7)),
              ),
            ),
          );
        }

        // Hata durumu
        if (snapshot.hasError) {
          debugPrint('Auth error: ${snapshot.error}');
          return const LoginPage(); // Hata durumunda login ekranına yönlendir
        }

        // Kullanıcı durumuna göre yönlendirme
        return snapshot.data != null ? const HomeScreen() : const LoginPage();
      },
    );
  }
}

ThemeData _buildThemeData(BuildContext context) {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 90, 20, 175),
      primary: const Color(0xFFE1BEE7),
      onPrimary: Colors.white,
      secondary: const Color.fromARGB(255, 239, 173, 240),
      onSecondary: Colors.white,
      tertiary: const Color.fromARGB(255, 193, 255, 159),
      onTertiary: Colors.white,
      background: Colors.grey.shade50,
      onBackground: Colors.black87,
      surface: Colors.white,
      onSurface: Colors.black87,
      surfaceVariant: Colors.grey.shade100,
      onSurfaceVariant: Colors.black54,
      error: Colors.red.shade700,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Roboto', fontSize: 34),
      headlineMedium: TextStyle(fontFamily: 'Roboto', fontSize: 28),
      titleLarge: TextStyle(fontFamily: 'Roboto', fontSize: 22),
      titleMedium: TextStyle(fontFamily: 'Roboto', fontSize: 18),
      bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16),
      bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      floatingLabelStyle: TextStyle(
        color: Theme.of(context).colorScheme.secondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
