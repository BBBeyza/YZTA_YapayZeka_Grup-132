import 'package:flutter/material.dart';

/// Her bir çizim noktasını temsil eden veri modeli.
class DrawingPoint {
  final Offset point;
  final DateTime timestamp;
  final double pressure;

  // Constructor'da super.key kullanılmaz, bu bir veri modelidir.
  const DrawingPoint({ // Const constructor ekledik
    required this.point,
    required this.timestamp,
    this.pressure = 1.0,
  });

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

/// Tamamlanmış bir çizgi parçasını (stroke) temsil eden veri modeli.
/// Bu sınıf, o çizgi için kullanılan renk ve kalınlık bilgilerini içerir.
class Stroke {
  final List<DrawingPoint> points;
  final Color color;
  final double width;

  // Constructor'da super.key kullanılmaz, bu bir veri modelidir.
  const Stroke({ // Const constructor ekledik
    required this.points,
    required this.color,
    required this.width,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Stroke &&
              runtimeType == other.runtimeType &&
              points == other.points &&
              color == other.color &&
              width == other.width;

  @override
  int get hashCode => points.hashCode ^ color.hashCode ^ width.hashCode;
}