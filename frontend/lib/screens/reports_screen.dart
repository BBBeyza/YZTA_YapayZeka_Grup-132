import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Raporlar'),
        backgroundColor: const Color(0xFFC8A2C8), // Ana sayfa temasına uygun renk
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Geçmişiniz',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              context,
              title: 'Bilişsel Test Raporu',
              description: 'Hafıza ve dikkat becerileri analizi',
              reportDate: '15 Kasım 2023',
              cardColor: const Color(0xFFC8A2C8), // Bilişsel testin rengi
            ),
            _buildReportCard(
              context,
              title: 'Çizim Testi Raporu',
              description: 'Görsel-motor koordinasyon analizi',
              reportDate: '12 Kasım 2023',
              cardColor: const Color(0xFFF9A825), // Çizim testinin rengi
            ),
            _buildReportCard(
              context,
              title: 'Sesli Okuma Testi Raporu',
              description: 'Okuma akıcılığı ve anlama analizi',
              reportDate: '10 Kasım 2023',
              cardColor: const Color.fromARGB(255, 191, 118, 135), // Sesli okuma testinin rengi
            ),
            const SizedBox(height: 16),
            Text(
              'Genel İlerleme Grafiği (Placeholder)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 16),
            // Buraya ileride grafik widget'ı eklenebilir
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'Grafik Alanı',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Rapor kartını oluşturan özel widget
  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String description,
    required String reportDate,
    required Color cardColor,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  reportDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Raporu görüntüleme işlevi
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title için rapor görüntüleniyor...'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Raporu Görüntüle'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
