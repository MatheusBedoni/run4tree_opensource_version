import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Desenha só o traçado do percurso, sem mapa — o "rabisco" que o Strava e o
/// adidas Running colocam sobre fotos. Centraliza e escala o trajeto para
/// caber no espaço disponível mantendo a proporção.
class RouteShapePainter extends CustomPainter {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;

  const RouteShapePainter({
    required this.points,
    required this.color,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.isEmpty) return;

    // Projeção equirretangular: suficiente para trajetos urbanos e evita que
    // percursos longe do equador pareçam esticados na vertical.
    final meanLat =
        points.fold<double>(0, (sum, p) => sum + p.latitude) / points.length;
    final lngScale = math.cos(meanLat * math.pi / 180);
    final projected = [
      for (final p in points) Offset(p.longitude * lngScale, -p.latitude),
    ];

    var minX = projected.first.dx;
    var maxX = minX;
    var minY = projected.first.dy;
    var maxY = minY;
    for (final p in projected) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final inset = strokeWidth * 1.5;
    final availableWidth = size.width - inset * 2;
    final availableHeight = size.height - inset * 2;
    if (availableWidth <= 0 || availableHeight <= 0) return;

    final spanX = maxX - minX;
    final spanY = maxY - minY;
    final scale = math.min(
      spanX > 0 ? availableWidth / spanX : double.infinity,
      spanY > 0 ? availableHeight / spanY : double.infinity,
    );
    // Todos os pontos no mesmo lugar: não há traçado para desenhar.
    if (!scale.isFinite) return;

    final dx = inset + (availableWidth - spanX * scale) / 2;
    final dy = inset + (availableHeight - spanY * scale) / 2;
    Offset toCanvas(Offset p) =>
        Offset(dx + (p.dx - minX) * scale, dy + (p.dy - minY) * scale);

    final first = toCanvas(projected.first);
    final path = Path()..moveTo(first.dx, first.dy);
    for (final p in projected.skip(1)) {
      final point = toCanvas(p);
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      toCanvas(projected.last),
      strokeWidth * 1.3,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(RouteShapePainter oldDelegate) =>
      !identical(oldDelegate.points, points) ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
