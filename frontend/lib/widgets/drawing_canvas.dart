import 'package:flutter/material.dart';
import 'package:neurograph/models/stroke.dart'; // Stroke sınıfını import ediyoruz

/// Uygulamada çizim yapılmasına olanak tanıyan StatefulWidget.
class DrawingCanvas extends StatefulWidget {
  final Color backgroundColor;

  const DrawingCanvas({ // super.key burada kullanılıyor
    super.key,
    this.backgroundColor = Colors.white,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

/// DrawingCanvas'ın durumunu yöneten State sınıfı.
/// Çizim noktalarını kaydeder, UI güncellemelerini tetikler.
class DrawingCanvasState extends State<DrawingCanvas> {
  List<Stroke> _allStrokes = [];
  List<Stroke> _undoneStrokes = [];
  List<DrawingPoint> _currentDrawingPoints = [];

  Color _strokeColor = Colors.black;
  double _strokeWidth = 3.0;

  final List<Color> _colorOptions = const [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.brown,
  ];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentDrawingPoints = [
        DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
      ];
      _undoneStrokes.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentDrawingPoints = List.from(_currentDrawingPoints)
        ..add(DrawingPoint(point: details.localPosition, timestamp: DateTime.now()));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Son noktayı ekle (eğer farklıysa ve bu son nokta zaten eklendiyse tekrar eklemeyi önle)
    if (_currentDrawingPoints.isNotEmpty &&
        (_currentDrawingPoints.last.point != details.localPosition ||
            _currentDrawingPoints.length == 1)) { // Tek nokta varsa da ekle
      _currentDrawingPoints.add(
        DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
      );
    } else if (_currentDrawingPoints.isEmpty) { // Hiç nokta eklenmemişse (sadece dokunup çekme)
      _currentDrawingPoints.add(
        DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
      );
    }

    setState(() {
      if (_currentDrawingPoints.isNotEmpty) {
        _allStrokes.add(Stroke(
          points: List.from(_currentDrawingPoints),
          color: _strokeColor,
          width: _strokeWidth,
        ));
      }
      _currentDrawingPoints = [];
    });
  }

  void clearCanvas() {
    setState(() {
      _allStrokes = [];
      _currentDrawingPoints = [];
      _undoneStrokes = [];
    });
  }

  void undo() {
    setState(() {
      if (_allStrokes.isNotEmpty) {
        final lastStroke = _allStrokes.removeLast();
        _undoneStrokes.add(lastStroke);
      }
    });
  }

  void redo() {
    setState(() {
      if (_undoneStrokes.isNotEmpty) {
        final lastUndoneStroke = _undoneStrokes.removeLast();
        _allStrokes.add(lastUndoneStroke);
      }
    });
  }

  List<DrawingPoint> getAllDrawingPoints() {
    List<DrawingPoint> allPoints = [];
    for (var stroke in _allStrokes) {
      allPoints.addAll(stroke.points);
    }
    allPoints.addAll(_currentDrawingPoints);
    return allPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControlPanel(),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: _DrawingPainter(
                    allStrokes: _allStrokes,
                    currentDrawingPoints: _currentDrawingPoints,
                    currentStrokeColor: _strokeColor,
                    currentStrokeWidth: _strokeWidth,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
              Row(
                children: [
                  const Icon(Icons.line_weight, color: Colors.grey, size: 20),
                  Expanded(
                    child: Slider(
                      value: _strokeWidth,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      label: _strokeWidth.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _strokeWidth = value;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
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
                            color: _strokeColor == color ? Theme.of(context).colorScheme.primary : Colors.transparent,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo, size: 24),
                    onPressed: _allStrokes.isNotEmpty ? undo : null,
                    tooltip: 'Geri Al',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, size: 24),
                    onPressed: _undoneStrokes.isNotEmpty ? redo : null,
                    tooltip: 'İleri Al',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all, size: 24),
                    onPressed: _allStrokes.isNotEmpty || _currentDrawingPoints.isNotEmpty ? clearCanvas : null,
                    tooltip: 'Tuvali Temizle',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
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
    for (var stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.width;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i].point, stroke.points[i + 1].point, paint);
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
    // Listelerin referans eşitliğini kontrol etmek yeterlidir, çünkü
    // listelerimizin içeriği değiştiğinde yeni referanslar oluşturuyoruz.
    return oldDelegate.allStrokes != allStrokes ||
        oldDelegate.currentDrawingPoints != currentDrawingPoints ||
        oldDelegate.currentStrokeColor != currentStrokeColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth;
  }
}