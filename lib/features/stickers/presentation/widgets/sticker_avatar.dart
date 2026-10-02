import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Avatar circular com a arte de um adesivo.
///
/// Usado no perfil, na coleção e no diálogo de desbloqueio — sempre com a mesma
/// moldura branca do marcador do mapa, para o usuário reconhecer que é "ele".
class StickerAvatar extends StatelessWidget {
  /// Caminho do PNG do adesivo. `null` cai no ícone de muda (estado inicial).
  final String? assetPath;

  final double size;

  /// Espessura da borda branca. 0 remove a moldura.
  final double borderWidth;

  final bool showShadow;

  const StickerAvatar({
    super.key,
    required this.assetPath,
    this.size = 96,
    this.borderWidth = 4,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        gradient: assetPath == null
            ? const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: borderWidth > 0
            ? Border.all(color: Colors.white, width: borderWidth)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: assetPath == null
          ? Center(
              child: FaIcon(
                FontAwesomeIcons.seedling,
                color: Colors.white,
                size: size * 0.38,
              ),
            )
          : ClipOval(
              child: Image.asset(
                assetPath!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}
