import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/map_styles.dart';
import '../../../../core/theme/app_colors.dart';

/// Formato da imagem exportada.
enum ShareFormat {
  story(aspectRatio: 9 / 16, routeTop: 0.13, routeHeight: 0.50),
  square(aspectRatio: 1, routeTop: 0.14, routeHeight: 0.36);

  const ShareFormat({
    required this.aspectRatio,
    required this.routeTop,
    required this.routeHeight,
  });

  /// Largura dividida pela altura.
  final double aspectRatio;

  /// Faixa vertical (fração da altura do card) onde o percurso é enquadrado
  /// no fundo de mapa: abaixo da marca no topo e acima do bloco de números.
  final double routeTop;
  final double routeHeight;
}

/// Abas do editor. Cada uma mostra uma faixa de opções diferente.
enum ShareEditorTab { photo, map, color, sticker }

/// O que está atrás dos números no card.
enum ShareBackgroundKind { photo, map, color }

enum ShareMapStyle {
  light(
    mapType: MapType.normal,
    json: MapStyles.shareLightStyle,
    routeColor: Color(0xFF111111),
    swatch: [Color(0xFFF2F3F0), Color(0xFFDCE3D8)],
  ),
  satellite(
    mapType: MapType.hybrid,
    json: MapStyles.shareSatelliteStyle,
    routeColor: Colors.white,
    swatch: [Color(0xFF6E6446), Color(0xFF2F3B24)],
  ),
  dark(
    mapType: MapType.normal,
    json: MapStyles.shareDarkStyle,
    routeColor: Colors.white,
    swatch: [Color(0xFF24324D), Color(0xFF141B2B)],
  ),
  cartoon(
    mapType: MapType.normal,
    json: MapStyles.cartoonStyle,
    routeColor: AppColors.primaryDark,
    swatch: [AppColors.progressTrack, AppColors.mapGrass],
  );

  const ShareMapStyle({
    required this.mapType,
    required this.json,
    required this.routeColor,
    required this.swatch,
  });

  final MapType mapType;

  /// Nunca nulo: o GoogleMap não volta ao estilo padrão quando `style` passa
  /// a ser `null`, então até o satélite tem um JSON próprio.
  final String json;

  final Color routeColor;

  /// Cores da miniatura na faixa de opções.
  final List<Color> swatch;
}

enum ShareColorStyle {
  forest(
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primaryLight, AppColors.primaryDark],
    ),
  ),
  sunrise(
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFAD961), Color(0xFFF76B1C)],
    ),
  ),
  night(
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2C5364), Color(0xFF0F2027)],
    ),
  ),

  /// Exporta PNG com fundo transparente, para usar como adesivo sobre uma
  /// foto no próprio Instagram (como o Strava faz).
  transparent(null);

  const ShareColorStyle(this.gradient);

  final Gradient? gradient;
}

/// Foto de fundo: uma arte do app ou uma imagem escolhida pelo usuário.
@immutable
class ShareCardPhoto {
  final String? assetPath;
  final String? filePath;

  const ShareCardPhoto.asset(String this.assetPath) : filePath = null;

  const ShareCardPhoto.file(String this.filePath) : assetPath = null;

  /// Artes do próprio app, sempre disponíveis.
  static const List<ShareCardPhoto> builtIn = [
    ShareCardPhoto.asset('assets/images/splash_screen.jpg'),
    ShareCardPhoto.asset('assets/images/icon.png'),
  ];

  ImageProvider get image =>
      filePath != null ? FileImage(File(filePath!)) : AssetImage(assetPath!);

  @override
  bool operator ==(Object other) =>
      other is ShareCardPhoto &&
      other.assetPath == assetPath &&
      other.filePath == filePath;

  @override
  int get hashCode => Object.hash(assetPath, filePath);
}
