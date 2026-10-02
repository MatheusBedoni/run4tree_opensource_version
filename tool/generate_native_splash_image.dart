// Gera a imagem que o flutter_native_splash usa como background em tela cheia.
//
// A arte original é um JPG de ~560 KB, mas o flutter_native_splash sempre grava
// o background como PNG e o copia para 4 lugares (2 drawables Android, iOS e
// web). Um PNG direto da arte dá ~3,8 MB por cópia; redimensionar para 1080 de
// largura e quantizar em 256 cores derruba para ~1,4 MB sem diferença visível.
//
// Rode depois de trocar a arte:
//   dart run tool/generate_native_splash_image.dart
//   dart run flutter_native_splash:create
import 'dart:io';

import 'package:image/image.dart';

const _source = 'assets/images/splash_screen.jpg';
const _destination = 'native_splash/splash_screen.png';

void main() {
  final source = decodeImage(File(_source).readAsBytesSync());
  if (source == null) {
    stderr.writeln('Não foi possível ler $_source');
    exit(1);
  }

  final resized = copyResize(
    source,
    width: 1080,
    interpolation: Interpolation.cubic,
  );
  final quantized = quantize(
    resized,
    numberOfColors: 256,
    dither: DitherKernel.floydSteinberg,
  );

  final file = File(_destination)
    ..createSync(recursive: true)
    ..writeAsBytesSync(encodePng(quantized, level: 9));

  stdout.writeln(
    '$_destination  ${quantized.width}x${quantized.height}  '
    '${(file.lengthSync() / 1024).round()} KB',
  );
}
