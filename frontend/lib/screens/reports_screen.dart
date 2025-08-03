import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  late Stream<List<Report>> _reportsStream;

  @override
  void initState() {
    super.initState();
    _reportsStream = _reportService.getUserReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Raporlar'),
        backgroundColor: const Color(0xFFC8A2C8),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Report>>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const Center(child: Text('Henüz rapor bulunmamaktadır'));
          }

          return SingleChildScrollView(
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
                ...reports.map(
                  (report) => _buildReportCard(context, report: report),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, {required Report report}) {
    Color getCardColor() {
      switch (report.type) {
        case 'cognitive':
          return const Color(0xFFC8A2C8);
        case 'drawing':
          return const Color(0xFFF9A825);
        case 'voice':
          return const Color.fromARGB(255, 191, 118, 135);
        default:
          return Colors.grey;
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: getCardColor(),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.type == 'cognitive'
                            ? 'Bilişsel Değerlendirme Raporu'
                            : report.type == 'drawing'
                            ? 'Çizim Testi Raporu'
                            : 'Sesli Okuma Raporu',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${report.date.day}/${report.date.month}/${report.date.year}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapor Özeti:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  report.content.length > 150
                      ? '${report.content.substring(0, 150)}...'
                      : report.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showFullReportDialog(context, report);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Tam Raporu Gör'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullReportDialog(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(child: Text(report.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
