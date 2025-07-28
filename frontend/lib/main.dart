// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurograph/screens/loginScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(); // .env dosyasını yükle

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroGraph',
      debugShowCheckedModeBanner: false,
      theme: _buildThemeData(context),
      home: const LoginPage(),
    );
  }
}

ThemeData _buildThemeData(BuildContext context) {
  // ... (Bu kısım aynı kalır) ...
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 90, 20, 175),
      primary: const Color.fromARGB(255, 125, 141, 213),
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
      floatingLabelStyle: TextStyle(
        color: Theme.of(context).colorScheme.secondary,
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
  );
}