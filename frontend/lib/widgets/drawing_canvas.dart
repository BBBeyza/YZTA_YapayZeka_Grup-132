import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:neurograph/models/stroke.dart';
import 'dart:ui' as ui; // UI görüntü işlemleri için
import 'dart:typed_data'; // Uint8List için

class DrawingCanvas extends StatefulWidget {
  final Color backgroundColor;

  // Arka plan rengini varsayılan olarak beyaz yapıyoruz
  const DrawingCanvas({super.key, this.backgroundColor = Colors.white});

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  List<Stroke> _allStrokes = [];
  // Geri alma/ileri alma fonksiyonları kaldırıldığı için _undoneStrokes artık gerekli değil
  // List<Stroke> _undoneStrokes = [];
  List<DrawingPoint> _currentDrawingPoints = [];

  // Fırça rengi ve kalınlığı sabitlendi
  Color _strokeColor = Colors.black;
  double _strokeWidth = 3.0; // Sabit fırça kalınlığı

  // Çizim alanını resme dönüştürmek için kullanılacak GlobalKey
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Renk seçenekleri geri getirildi
  final List<Color> _colorOptions = const [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.pink,
    Colors.orange,
    Colors.purple,
  ];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentDrawingPoints = [
        DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
      ];
      // _undoneStrokes.clear(); // Geri alma kaldırıldığı için bu satır da kaldırıldı
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentDrawingPoints = List.from(_currentDrawingPoints)
        ..add(
          DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
        );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentDrawingPoints.isNotEmpty &&
        (_currentDrawingPoints.last.point != details.localPosition ||
            _currentDrawingPoints.length == 1)) {
      _currentDrawingPoints.add(
        DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
      );
    } else if (_currentDrawingPoints.isEmpty) {
      _currentDrawingPoints.add(
        DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
      );
    }

    setState(() {
      if (_currentDrawingPoints.isNotEmpty) {
        _allStrokes.add(
          Stroke(
            points: List.from(_currentDrawingPoints),
            color: _strokeColor,
            width: _strokeWidth,
          ),
        );
      }
      _currentDrawingPoints = [];
    });
  }

  // clearCanvas, undo, redo fonksiyonları kaldırıldı
  // void clearCanvas() {
  //   setState(() {
  //     _allStrokes = [];
  //     _currentDrawingPoints = [];
  //     _undoneStrokes = [];
  //   });
  // }

  // void undo() {
  //   setState(() {
  //     if (_allStrokes.isNotEmpty) {
  //       final lastStroke = _allStrokes.removeLast();
  //       _undoneStrokes.add(lastStroke);
  //     }
  //   });
  // }

  // void redo() {
  //   setState(() {
  //     if (_undoneStrokes.isNotEmpty) {
  //       final lastUndoneStroke = _undoneStrokes.removeLast();
  //       _allStrokes.add(lastUndoneStroke);
  //     }
  //   });
  // }

  List<DrawingPoint> getAllDrawingPoints() {
    List<DrawingPoint> allPoints = [];
    for (var stroke in _allStrokes) {
      allPoints.addAll(stroke.points);
    }
    allPoints.addAll(_currentDrawingPoints);
    return allPoints;
  }

  /// Çizimi PNG formatında Uint8List olarak dışa aktarır.
  /// Görüntüye beyaz arka plan ekler.
  Future<Uint8List?> exportDrawingAsPngBytes() async {
    try {
      final RenderRepaintBoundary boundary =
      _repaintBoundaryKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;

      // RenderRepaintBoundary'nin boyutunu al
      final ui.Size imageSize = boundary.size;

      // Yeni bir resim kaydedici (recorder) oluştur
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imageSize.width, imageSize.height));

      // Kanvasın tamamını beyaz arka planla doldur
      canvas.drawRect(Rect.fromLTWH(0, 0, imageSize.width, imageSize.height), Paint()..color = Colors.white);

      // Tüm mevcut çizimleri bu yeni kanvas üzerine yeniden çiz
      for (var stroke in _allStrokes) {
        if (stroke.points.isEmpty) continue;
        final paint = Paint()
          ..color = stroke.color
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke.width;
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i].point, stroke.points[i + 1].point, paint);
        }
      }
      // Mevcut çizim noktalarını da çiz (eğer varsa)
      if (_currentDrawingPoints.isNotEmpty) {
        final currentPaint = Paint()
          ..color = _strokeColor // Sabitlenen çizgi rengini kullan
          ..strokeCap = StrokeCap.round
          ..strokeWidth = _strokeWidth; // Sabitlenen çizgi kalınlığını kullan
        for (int i = 0; i < _currentDrawingPoints.length - 1; i++) {
          canvas.drawLine(_currentDrawingPoints[i].point, _currentDrawingPoints[i + 1].point, currentPaint);
        }
      }

      // Kaydı tamamla ve bir ui.Picture nesnesi al
      final ui.Picture picture = recorder.endRecording();
      // ui.Picture'ı ui.Image'a dönüştür
      final ui.Image image = await picture.toImage(imageSize.width.toInt(), imageSize.height.toInt());

      // ui.Image'ı PNG ByteData'ya dönüştür
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Çizimi resme dönüştürme hatası: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kontrol paneli geri getirildi
        _buildControlPanel(),
        Expanded(
          child: AspectRatio( // Tuvali kare yapmak için AspectRatio eklendi
            aspectRatio: 1.0, // 1:1 oranında kare
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: widget.backgroundColor, // Bu zaten varsayılan olarak beyaz
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                // Burayı RepaintBoundary ile sarıyoruz
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: _DrawingPainter(
                        allStrokes: _allStrokes,
                        currentDrawingPoints: _currentDrawingPoints,
                        currentStrokeColor: _strokeColor, // Sabit renk
                        currentStrokeWidth: _strokeWidth, // Sabit kalınlık
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // _buildControlPanel metodu geri getirildi ve sadeleştirildi
  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fırça boyutu slider'ı kaldırıldı
              // Row(
              //   children: [
              //     const Icon(Icons.line_weight, color: Colors.grey, size: 20),
              //     Expanded(
              //       child: Slider(
              //         value: _strokeWidth,
              //         min: 1.0,
              //         max: 10.0,
              //         divisions: 9,
              //         label: _strokeWidth.round().toString(),
              //         onChanged: (double value) {
              //           setState(() {
              //             _strokeWidth = value;
              //           });
              //         },
              //         activeColor: Theme.of(context).colorScheme.primary,
              //         inactiveColor: Colors.grey.shade300,
              //       ),
              //     ),
              //   ],
              // ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colorOptions.length,
                  itemBuilder: (context, index) {
                    final color = _colorOptions[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _strokeColor = color;
                        });
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _strokeColor == color
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: _strokeColor == color ? 3.0 : 1.0,
                          ),
                          boxShadow: [
                            if (_strokeColor == color)
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Geri al/ileri al/temizle butonları kaldırıldı
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceAround,
              //   children: [
              //     IconButton(
              //       icon: const Icon(Icons.undo, size: 24),
              //       onPressed: _allStrokes.isNotEmpty ? undo : null,
              //       tooltip: 'Geri Al',
              //       color: Theme.of(context).colorScheme.primary,
              //     ),
              //     IconButton(
              //       icon: const Icon(Icons.redo, size: 24),
              //       onPressed: _undoneStrokes.isNotEmpty ? redo : null,
              //       tooltip: 'İleri Al',
              //       color: Theme.of(context).colorScheme.primary,
              //     ),
              //     IconButton(
              //       icon: const Icon(Icons.clear_all, size: 24),
              //       onPressed:
              //           _allStrokes.isNotEmpty ||
              //               _currentDrawingPoints.isNotEmpty
              //           ? clearCanvas
              //           : null,
              //       tooltip: 'Tuvali Temizle',
              //       color: Theme.of(context).colorScheme.error,
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> allStrokes;
  final List<DrawingPoint> currentDrawingPoints;
  final Color currentStrokeColor;
  final double currentStrokeWidth;

  _DrawingPainter({
    required this.allStrokes,
    required this.currentDrawingPoints,
    required this.currentStrokeColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Arka planı burada çizmiyoruz, çünkü exportDrawingAsPngBytes metodu zaten beyaz arka planla çiziyor.
    // Eğer burada da çizilirse, tuvalde beyaz arka plan görünecektir.
    // canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    for (var stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.width;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(
          stroke.points[i].point,
          stroke.points[i + 1].point,
          paint,
        );
      }
    }

    if (currentDrawingPoints.isNotEmpty) {
      final currentPaint = Paint()
        ..color = currentStrokeColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = currentStrokeWidth;

      for (int i = 0; i < currentDrawingPoints.length - 1; i++) {
        canvas.drawLine(
          currentDrawingPoints[i].point,
          currentDrawingPoints[i + 1].point,
          currentPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.allStrokes != allStrokes ||
        oldDelegate.currentDrawingPoints != currentDrawingPoints ||
        oldDelegate.currentStrokeColor != currentStrokeColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth;
  }
}
