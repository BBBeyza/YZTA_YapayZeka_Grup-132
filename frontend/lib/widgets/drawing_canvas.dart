import 'package:flutter/material.dart';

/// Her bir çizim noktasını temsil eden veri modeli.
/// `point`: Ekrandaki konumu (Offset).
/// `timestamp`: Noktanın kaydedildiği zaman.
/// `pressure`: Basınç bilgisi (şu an için varsayılan 1.0, gelecekteki geliştirmeler için).
class DrawingPoint {
  final Offset point;
  final DateTime timestamp;
  final double pressure;

  DrawingPoint({
    required this.point,
    required this.timestamp,
    this.pressure = 1.0,
  });

  // Gerekirse eşitlik kontrolü için
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingPoint &&
          runtimeType == other.runtimeType &&
          point == other.point &&
          timestamp == other.timestamp &&
          pressure == other.pressure;

  @override
  int get hashCode => point.hashCode ^ timestamp.hashCode ^ pressure.hashCode;
}

/// Uygulamada çizim yapılmasına olanak tanıyan StatefulWidget.
/// Kullanıcının parmak/kalem hareketlerini algılar ve çizim verilerini kaydeder.
class DrawingCanvas extends StatefulWidget {
  final Color backgroundColor;
  final Color strokeColor;
  final double strokeWidth;

  const DrawingCanvas({
    super.key,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
  });

  @override
  // createState metodu, State sınıfını döndürür.
  State<DrawingCanvas> createState() => DrawingCanvasState(); // Public olan State sınıfı
}

/// DrawingCanvas'ın durumunu yöneten State sınıfı.
/// Çizim noktalarını kaydeder, UI güncellemelerini tetikler.
class DrawingCanvasState extends State<DrawingCanvas> {
  // Şu an çizilmekte olan çizginin noktaları.
  List<DrawingPoint> _currentStroke = [];
  // Tamamlanmış (kalemin kaldırıldığı) tüm çizgilerin listesi.
  List<List<DrawingPoint>> _allStrokes = [];

  // Nokta sıkıştırma için son kaydedilen nokta.
  Offset? _lastPoint;
  // Nokta kaydedilmeden önceki minimum hareket mesafesi (piksel).
  static const double _minDistance = 3.0; // Ayarlanabilir değer

  /// Kullanıcı ekrana dokunmaya başladığında çağrılır.
  void _onPanStart(DragStartDetails details) {
    // setState ile UI'ı güncelleyerek yeni çizime başla.
    setState(() {
      _currentStroke = [
        DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
      ];
      // İlk noktayı son kaydedilen nokta olarak ayarla.
      _lastPoint = details.localPosition;
    });
  }

  /// Kullanıcı parmağını/kalemini hareket ettirirken çağrılır.
  void _onPanUpdate(DragUpdateDetails details) {
    // Eğer son kaydedilen nokta yoksa (ilk kez hareket ediliyorsa)
    // veya belirli bir mesafeden fazla hareket edildiyse, yeni nokta kaydet.
    if (_lastPoint == null ||
        (details.localPosition - _lastPoint!).distance > _minDistance) {
      // setState ile UI'ı güncelleyerek mevcut çizime yeni nokta ekle.
      setState(() {
        _currentStroke.add(
          DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
        );
        // Son kaydedilen noktayı güncelle.
        _lastPoint = details.localPosition;
      });
    }
  }

  /// Kullanıcı parmağını/kalemini ekrandan kaldırdığında çağrılır.
  void _onPanEnd(DragEndDetails details) {
    // Çizim bitince son noktayı (eğer farklıysa) ekle.
    if (_currentStroke.isNotEmpty &&
        _currentStroke.last.point != details.localPosition) {
      _currentStroke.add(
        DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
      );
    }

    // Tamamlanmış _currentStroke'u _allStrokes listesine ekle (bir kopyasını).
    // Ardından _currentStroke'u bir sonraki çizim için temizle.
    setState(() {
      if (_currentStroke.isNotEmpty) {
        _allStrokes.add(List.from(_currentStroke)); // Kopyasını eklemek önemli!
      }
      _currentStroke = [];
      _lastPoint = null;
    });
    // Burada artık onDrawingFinished çağrılmıyor, dışarıdaki buton tetikleyecek.
  }

  /// Tuvali ve tüm çizim verilerini temizler.
  void clearCanvas() {
    setState(() {
      _allStrokes = [];
      _currentStroke = [];
      _lastPoint = null;
    });
  }

  /// Kaydedilecek çizim verilerini dışarıya sunan yeni metod.
  /// Bu metod, GlobalKey aracılığıyla dışarıdan çağrılacak.
  List<DrawingPoint> getAllDrawingPoints() {
    // Mevcut (henüz kaydedilmemiş) çizgiyi de dahil ederek tüm noktaları döndür.
    // Eğer mouse hala basılıysa _currentStroke'da noktalar olabilir.
    List<List<DrawingPoint>> currentAllStrokes = List.from(_allStrokes);
    if (_currentStroke.isNotEmpty) {
      currentAllStrokes.add(List.from(_currentStroke));
    }
    return currentAllStrokes.expand((element) => element).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        color: widget.backgroundColor,
        child: CustomPaint(
          // _DrawingPainter'a hem tamamlanmış hem de anlık çizilen çizgiyi gönder.
          painter: _DrawingPainter(
            allStrokes: _allStrokes,
            currentStroke: _currentStroke, // Canlı çizim için
            strokeColor: widget.strokeColor,
            strokeWidth: widget.strokeWidth,
          ),
          child: ConstrainedBox(
            constraints:
                BoxConstraints.expand(), // Tuvalin tüm alanı kaplamasını sağlar.
          ),
        ),
      ),
    );
  }
}

/// Çizim işlemlerini gerçekten gerçekleştiren CustomPainter sınıfı.
/// UI güncellendiğinde yeniden çizim yapar.
class _DrawingPainter extends CustomPainter {
  // Tamamlanmış tüm çizgiler (kalem kaldırıldıktan sonra).
  final List<List<DrawingPoint>> allStrokes;
  // Anlık olarak çizilmekte olan çizgi.
  final List<DrawingPoint> currentStroke;
  final Color strokeColor;
  final double strokeWidth;

  _DrawingPainter({
    required this.allStrokes,
    required this.currentStroke, // Yeni eklendi
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          strokeColor // Çizgi rengi
      ..strokeCap = StrokeCap
          .round // Çizgi uçlarının yuvarlak olması
      ..strokeWidth = strokeWidth; // Çizgi kalınlığı

    // Tamamlanmış tüm çizgileri çiz.
    for (var stroke in allStrokes) {
      if (stroke.isEmpty) continue; // Boş çizgileri atla
      for (int i = 0; i < stroke.length - 1; i++) {
        // İki nokta arasında çizgi çek.
        canvas.drawLine(stroke[i].point, stroke[i + 1].point, paint);
      }
    }

    // O an çizilmekte olan çizgiyi çiz.
    // Bu kısım, gecikmeyi ortadan kaldırarak anlık çizimi sağlar.
    if (currentStroke.isNotEmpty) {
      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(
          currentStroke[i].point,
          currentStroke[i + 1].point,
          paint,
        );
      }
    }
  }

  @override
  // Yeniden çizim yapılıp yapılmayacağını kontrol eden metod.
  // Yalnızca çizim verileri değiştiğinde (performans için kritik) true döndürmeli.
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.allStrokes != allStrokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}
