// lib/widgets/app_bottom_navigation_bar.dart
import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex; // Seçili sekmeyi belirtmek için
  final ValueChanged<int> onTap; // Sekme tıklandığında ne olacağını belirtmek için
  final Color selectedItemColor; // Seçili öğe rengi
  final Color unselectedItemColor; // Seçili olmayan öğe rengi

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.selectedItemColor,
    required this.unselectedItemColor,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      type: BottomNavigationBarType.fixed, // Fixed tipinde olması ikonların metinlerin hep görünmesini sağlar
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
          icon: Icon(Icons.folder_open), // Raporlar için Icons.folder_open (Anasayfadaki gibi)
          label: 'Raporlar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline), // Profil için Icons.person_outline (Anasayfadaki gibi)
          label: 'Profil',
        ),
      ],
    );
  }
}