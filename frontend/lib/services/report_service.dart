import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addReport(Report report) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // userId'yi mutlaka ekleyin
      final reportData = report.toMap();
      reportData['userId'] = user.uid;

      await _firestore.collection('reports').doc(report.id).set(reportData);
    } catch (e) {
      throw Exception('Rapor eklenemedi: $e');
    }
  }

  // Kullanıcının raporlarını getirme
  Stream<List<Report>> getUserReports() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Report.fromMap(doc.data())).toList(),
        );
  }

  Future<void> addDrawingTestReport({
    required String testType,
    required String testTitle,
    required String analysisResult,
    required String geminiEvaluation,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '$testTitle Test Raporu',
        content:
            '''
  **Test Türü:** ${testType.toUpperCase()}
  **Analiz Sonucu:** $analysisResult
  **Değerlendirme:** $geminiEvaluation
  ''',
        date: DateTime.now(),
        type: 'drawing',
        userId: user.uid,
      );

      await addReport(report);
    } catch (e) {
      throw Exception('Çizim testi raporu eklenemedi: $e');
    }
  }
}
