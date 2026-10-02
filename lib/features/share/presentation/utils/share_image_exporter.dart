import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Rasteriza o card de compartilhamento em um PNG no diretório temporário.
class ShareImageExporter {
  const ShareImageExporter._();

  static const String _filePrefix = 'run4tree_share_';

  /// Captura o [RepaintBoundary] de [boundaryKey] com [targetWidth] pixels de
  /// largura — a altura segue a proporção do card.
  static Future<XFile> capture(
    GlobalKey boundaryKey, {
    required double targetWidth,
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Share card is not mounted');
    }

    final image = await boundary.toImage(
      pixelRatio: targetWidth / boundary.size.width,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG encoding failed');

      final directory = await getTemporaryDirectory();
      await _deletePreviousExports(directory);
      final file = File(
        p.join(
          directory.path,
          '$_filePrefix${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return XFile(file.path, mimeType: 'image/png');
    } finally {
      image.dispose();
    }
  }

  /// Cada exportação gera um PNG de alguns MB; mantém só o mais recente.
  static Future<void> _deletePreviousExports(Directory directory) async {
    try {
      await for (final entity in directory.list()) {
        if (entity is File && p.basename(entity.path).startsWith(_filePrefix)) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('ShareImageExporter cleanup error: $e');
    }
  }
}
