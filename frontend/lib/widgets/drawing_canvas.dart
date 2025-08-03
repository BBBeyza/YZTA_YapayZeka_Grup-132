import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:neurograph/models/stroke.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class DrawingCanvas extends StatefulWidget {
  final Color backgroundColor;

  const DrawingCanvas({
    super.key,
    this.backgroundColor = Colors.white,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  List<Stroke> _allStrokes = [];
  List<DrawingPoint> _currentDrawingPoints = [];

  Color _strokeColor = Colors.black;
  double _strokeWidth = 3.0;

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  final List<Color> _colorOptions = const [
    Colors.black,
    Colors.brown,
    Colors.red,
    Color.fromARGB(255, 255, 147, 23),
    Color.fromARGB(255, 247, 207, 31),
    Colors.green,
    Color.fromARGB(255, 52, 95, 235),
    Color.fromARGB(255, 113, 26, 163),
    Color.fromARGB(255, 243, 89, 179),
  ];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentDrawingPoints = [
        DrawingPoint(point: details.localPosition, timestamp: DateTime.now()),
      ];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentDrawingPoints = List.from(_currentDrawingPoints)
        ..add(DrawingPoint(point: details.localPosition, timestamp: DateTime.now()));
    });
  }

  void _onPanEnd(DragEndDetails details) {
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
    setState(() {});
  }

  List<DrawingPoint> getAllDrawingPoints() {
    return [..._allStrokes.expand((s) => s.points), ..._currentDrawingPoints];
  }

  Future<Uint8List?> exportDrawingAsPngBytes() async {
    try {
      final RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Size imageSize = boundary.size;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imageSize.width, imageSize.height));

      canvas.drawRect(Rect.fromLTWH(0, 0, imageSize.width, imageSize.height), Paint()..color = Colors.white);

      for (var stroke in _allStrokes) {
        if (stroke.points.isEmpty) continue;
        final paint = Paint()
          ..color = stroke.color
          ..strokeCap = ui.StrokeCap.round
          ..strokeWidth = stroke.width;
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i].point, stroke.points[i + 1].point, paint);
        }
      }

      if (_currentDrawingPoints.isNotEmpty) {
        final currentPaint = Paint()
          ..color = _strokeColor
          ..strokeCap = ui.StrokeCap.round
          ..strokeWidth = _strokeWidth;
        for (int i = 0; i < _currentDrawingPoints.length - 1; i++) {
          canvas.drawLine(_currentDrawingPoints[i].point, _currentDrawingPoints[i + 1].point, currentPaint);
        }
      }

      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(imageSize.width.toInt(), imageSize.height.toInt());

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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
        _buildControlPanel(),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
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
                        currentStrokeColor: _strokeColor,
                        currentStrokeWidth: _strokeWidth,
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

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
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
        ..strokeCap = ui.StrokeCap.round
        ..strokeWidth = stroke.width;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i].point, stroke.points[i + 1].point, paint);
      }
    }

    if (currentDrawingPoints.isNotEmpty) {
      final currentPaint = Paint()
        ..color = currentStrokeColor
        ..strokeCap = ui.StrokeCap.round
        ..strokeWidth = currentStrokeWidth;
      for (int i = 0; i < currentDrawingPoints.length - 1; i++) {
        canvas.drawLine(currentDrawingPoints[i].point, currentDrawingPoints[i + 1].point, currentPaint);
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
