import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/loginScreen.dart';
import 'services/auth_service.dart';
import 'screens/homePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await dotenv.load();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
      home: StreamBuilder<User?>(
        stream: AuthService().user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }

  ThemeData _buildThemeData(BuildContext context) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
