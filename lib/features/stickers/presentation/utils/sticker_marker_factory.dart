import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Transforma a arte de um adesivo no marcador do usuário no mapa.
///
/// O PNG é desenhado dentro de um círculo com moldura branca e sombra — a mesma
/// linguagem visual do [StickerAvatar], para o marcador ser reconhecido como
/// "eu" no mapa. O resultado é cacheado por adesivo + densidade de tela, já que
/// gerar o bitmap custa uma decodificação de imagem.
class StickerMarkerFactory {
  const StickerMarkerFactory._();

  static const double _canvasSize = 68; // px lógicos, incluindo folga da sombra
  static const double _borderWidth = 3;

  static final Map<String, BitmapDescriptor> _cache = {};

  /// Bitmap circular do adesivo em [assetPath].
  static Future<BitmapDescriptor> build({
    required String assetPath,
    required double devicePixelRatio,
  }) async {
    final cacheKey = '$assetPath@$devicePixelRatio';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final descriptor = await _render(assetPath, devicePixelRatio);
    _cache[cacheKey] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> _render(
    String assetPath,
    double devicePixelRatio,
  ) async {
    final sizePx = _canvasSize * devicePixelRatio;
    final center = Offset(sizePx / 2, sizePx / 2);
    // Folga para a sombra não ser cortada na borda do bitmap.
    final outerRadius = sizePx / 2 - 4 * devicePixelRatio;
    final innerRadius = outerRadius - _borderWidth * devicePixelRatio;

    final image = await _loadImage(assetPath, (innerRadius * 2).round());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      center.translate(0, 2 * devicePixelRatio),
      outerRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          2.5 * devicePixelRatio,
        ),
    );
    canvas.drawCircle(center, outerRadius, Paint()..color = Colors.white);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCircle(center: center, radius: innerRadius),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
    image.dispose();

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(sizePx.round(), sizePx.round());
    picture.dispose();

    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    rendered.dispose();

    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: devicePixelRatio,
    );
  }

  static Future<ui.Image> _loadImage(String assetPath, int targetWidth) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}
