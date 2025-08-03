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
    if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

    return _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Report.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }
}
