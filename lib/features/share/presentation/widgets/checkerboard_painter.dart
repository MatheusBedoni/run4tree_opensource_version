import 'package:flutter/rendering.dart';

/// Xadrez cinza que sinaliza "fundo transparente" na prévia. Fica fora da
/// área capturada, então não aparece na imagem exportada.
class CheckerboardPainter extends CustomPainter {
  final double cellSize;

  const CheckerboardPainter({this.cellSize = 12});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final dark = Paint()..color = const Color(0xFFE0E0E0);
    final columns = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();
    for (var row = 0; row < rows; row++) {
      for (var column = row.isEven ? 1 : 0; column < columns; column += 2) {
        canvas.drawRect(
          Rect.fromLTWH(column * cellSize, row * cellSize, cellSize, cellSize),
          dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CheckerboardPainter oldDelegate) =>
      oldDelegate.cellSize != cellSize;
}
