import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Converte a polyline salva na sessão (`[[lat, lng], ...]` em JSON) em
/// pontos do mapa. Atividades sem GPS ou com dado corrompido viram lista vazia.
List<LatLng> decodeRoutePoints(String polyline) {
  if (polyline.isEmpty) return const [];
  try {
    final list = jsonDecode(polyline) as List<dynamic>;
    return [
      for (final element in list)
        LatLng(
          double.parse(element[0].toString()),
          double.parse(element[1].toString()),
        ),
    ];
  } catch (_) {
    return const [];
  }
}
