import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/share_options.dart';

/// Menor recorte do mapa (~160 m), para trajetos curtos não virarem um zoom
/// máximo sem contexto nenhum.
const double _minSpanDegrees = 0.0015;

/// Margem lateral livre, em fração da largura.
const double _horizontalInset = 0.1;

/// Câmera que enquadra o percurso na faixa livre do card ([ShareFormat.routeTop]
/// e [ShareFormat.routeHeight]), deixando o bloco de números por cima de mapa
/// e não por cima do trajeto.
///
/// Calcula centro e zoom direto, sem `newLatLngBounds`: isso funciona já como
/// câmera inicial (sem esperar o mapa medir o próprio tamanho) e mantém o logo
/// do Google no canto, onde o `padding` do GoogleMap o tiraria.
CameraPosition shareRouteCamera({
  required List<LatLng> points,
  required Size viewport,
  required ShareFormat format,
}) {
  if (points.isEmpty) {
    return const CameraPosition(target: LatLng(0, 0), zoom: 2);
  }
  if (viewport.isEmpty) {
    return CameraPosition(target: points.first, zoom: 15);
  }

  var minLat = points.first.latitude;
  var maxLat = minLat;
  var minLng = points.first.longitude;
  var maxLng = minLng;
  for (final point in points) {
    minLat = math.min(minLat, point.latitude);
    maxLat = math.max(maxLat, point.latitude);
    minLng = math.min(minLng, point.longitude);
    maxLng = math.max(maxLng, point.longitude);
  }

  final centerLat = (minLat + maxLat) / 2;
  final centerLng = (minLng + maxLng) / 2;

  // Na projeção de Mercator, 1° de latitude ocupa sec(lat) vezes a tela de
  // 1° de longitude. Tudo abaixo fica em "graus de longitude".
  final secLat = 1 / math.cos(centerLat * math.pi / 180);
  final spanLng = math.max(maxLng - minLng, _minSpanDegrees);
  final spanLat = math.max(maxLat - minLat, _minSpanDegrees) * secLat;

  final regionWidth = viewport.width * (1 - 2 * _horizontalInset);
  final regionHeight = viewport.height * format.routeHeight;
  final degreesPerPixel = math.max(
    spanLng / regionWidth,
    spanLat / regionHeight,
  );

  // No zoom z o mundo tem 256 · 2^z pixels lógicos para 360°.
  final zoom = (math.log(360 / (256 * degreesPerPixel)) / math.ln2).clamp(
    2.0,
    19.0,
  );
  final effectiveDegreesPerPixel = 360 / (256 * math.pow(2, zoom));

  // Desce o centro da câmera para o percurso subir até o meio da faixa livre.
  final routeCenterY = format.routeTop + format.routeHeight / 2;
  final offsetLat =
      (0.5 - routeCenterY) *
      viewport.height *
      effectiveDegreesPerPixel /
      secLat;

  return CameraPosition(
    target: LatLng(centerLat - offsetLat, centerLng),
    zoom: zoom,
  );
}
