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

      // Test tipine göre daha anlamlı başlık oluştur
      String reportTitle = _getReportTitle(testType, testTitle);
      
      // Rapor içeriğini daha düzenli hale getir
      String formattedContent = _formatReportContent(
        testType, 
        analysisResult, 
        geminiEvaluation
      );

      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: reportTitle,
        content: formattedContent,
        date: DateTime.now(),
        type: 'drawing',
        userId: user.uid,
      );

      await addReport(report);
    } catch (e) {
      throw Exception('Çizim testi raporu eklenemedi: $e');
    }
  }

  String _getReportTitle(String testType, String testTitle) {
    switch (testType.toLowerCase()) {
      case 'clock':
        return 'Saat Çizimi Test Raporu';
      case 'spiral':
        return 'Spiral Çizimi Test Raporu';
      case 'meander':
        return 'Meander Çizimi Test Raporu';
      case 'handwriting':
        return 'El Yazısı Test Raporu';
      default:
        return '$testTitle Test Raporu';
    }
  }

  String _formatReportContent(String testType, String analysisResult, String geminiEvaluation) {
    StringBuffer content = StringBuffer();
    
    // Test tipine göre özel açıklama ekle
    switch (testType.toLowerCase()) {
      case 'clock':
        content.writeln('Saat Çizimi Testi - Bilişsel Değerlendirme');
        content.writeln('Bu test, görsel-mekansal becerileri, planlama yetisi ve hafıza işlevlerini değerlendirir.\n');
        break;
      case 'spiral':
        content.writeln('Spiral Çizimi Testi - Motor Beceri Analizi');
        content.writeln('Bu test, el-göz koordinasyonu, motor kontrol ve hareket akıcılığını ölçer.\n');
        break;
      case 'meander':
        content.writeln('Meander Çizimi Testi - Koordinasyon Değerlendirmesi');
        content.writeln('Bu test, karmaşık çizgi takibi, dikkat ve motor koordinasyonu becerilerini analiz eder.\n');
        break;
      case 'handwriting':
        content.writeln('El Yazısı Testi - Yazma Becerileri Analizi');
        content.writeln('Bu test, doğal el yazısının akıcılığı, okunabilirliği ve motor kontrolünü değerlendirir.\n');
        break;
      default:
        content.writeln('Çizim Testi Analizi\n');
        break;
    }

    // Analiz sonuçlarını ekle
    if (analysisResult.isNotEmpty) {
      content.writeln('Analiz Sonuçları:');
      content.writeln(analysisResult);
      content.writeln();
    }

    // AI değerlendirmesini ekle
    if (geminiEvaluation.isNotEmpty) {
      content.writeln('Detaylı Değerlendirme:');
      content.writeln(geminiEvaluation);
    }

    return content.toString().trim();
  }

  // Cognitive test raporu ekleme fonksiyonu da eklenebilir
  Future<void> addCognitiveTestReport({
    required String testTitle,
    required Map<String, dynamic> testResults,
    required String evaluation,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '$testTitle Bilişsel Test Raporu',
        content: '''
Bilişsel Test Sonuçları

Test: $testTitle
Sonuçlar: ${testResults.toString()}
Değerlendirme: $evaluation
        ''',
        date: DateTime.now(),
        type: 'cognitive',
        userId: user.uid,
      );

      await addReport(report);
    } catch (e) {
      throw Exception('Bilişsel test raporu eklenemedi: $e');
    }
  }
}