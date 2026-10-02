import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../exercises/presentation/utils/exercise_formatters.dart';
import '../../../runs/domain/entities/run_session_entity.dart';
import '../../../stickers/presentation/widgets/sticker_avatar.dart';
import 'route_shape_painter.dart';

/// Famílias tipográficas do card. Injetáveis para os testes não dependerem
/// do download do Google Fonts.
class ShareCardFonts {
  /// Números e marca (condensada, estilo placar).
  final String? display;

  /// Nome da modalidade (serifada, como no adidas Running).
  final String? title;

  const ShareCardFonts({this.display, this.title});

  factory ShareCardFonts.brand() => ShareCardFonts(
    display: GoogleFonts.bebasNeue().fontFamily,
    title: GoogleFonts.dmSerifDisplay().fontFamily,
  );
}

/// Arte compartilhável de uma atividade: o fundo escolhido, a marca do app,
/// os números principais e o impacto em árvores.
///
/// Todas as medidas são frações da largura, então a mesma composição serve
/// para a prévia na tela e para a exportação em 1080 px.
class ShareRunCard extends StatelessWidget {
  final RunSessionEntity run;
  final Widget background;
  final List<LatLng> routePoints;

  /// Mostra o traçado do percurso ao lado do título — desligado quando o
  /// fundo já é o mapa.
  final bool showRouteShape;

  /// Sem véus escuros: o PNG sai com fundo transparente.
  final bool transparent;

  final String? stickerAssetPath;

  /// Canto superior esquerdo do adesivo, em fração do card (0 a 1).
  final Offset stickerOrigin;

  /// Recebe a nova origem enquanto o usuário arrasta o adesivo.
  final ValueChanged<Offset>? onStickerMoved;

  final ShareCardFonts fonts;

  /// Diâmetro do adesivo em fração da largura do card.
  static const double stickerSizeFactor = 0.24;

  static const Offset defaultStickerOrigin = Offset(0.06, 0.05);

  const ShareRunCard({
    super.key,
    required this.run,
    required this.background,
    this.routePoints = const [],
    this.showRouteShape = true,
    this.transparent = false,
    this.stickerAssetPath,
    this.stickerOrigin = defaultStickerOrigin,
    this.onStickerMoved,
    this.fonts = const ShareCardFonts(),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final unit = size.width / 100;

        return Stack(
          fit: StackFit.expand,
          children: [
            background,
            // Tudo por cima do fundo deixa os gestos passarem para o mapa.
            IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!transparent) const _Scrims(),
                  Positioned(
                    top: 5 * unit,
                    right: 5 * unit,
                    child: _Wordmark(unit: unit, fonts: fonts),
                  ),
                  Positioned(
                    left: 6 * unit,
                    right: 6 * unit,
                    bottom: 6 * unit,
                    child: _StatsBlock(
                      run: run,
                      unit: unit,
                      fonts: fonts,
                      routePoints: showRouteShape ? routePoints : const [],
                    ),
                  ),
                ],
              ),
            ),
            if (stickerAssetPath != null) _buildSticker(size),
          ],
        );
      },
    );
  }

  Widget _buildSticker(Size size) {
    final diameter = size.width * stickerSizeFactor;
    final maxX = 1 - diameter / size.width;
    final maxY = 1 - diameter / size.height;
    final origin = Offset(
      stickerOrigin.dx.clamp(0.0, maxX),
      stickerOrigin.dy.clamp(0.0, maxY),
    );

    return Positioned(
      left: origin.dx * size.width,
      top: origin.dy * size.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onStickerMoved == null
            ? null
            : (details) => onStickerMoved!(
                Offset(
                  (origin.dx + details.delta.dx / size.width).clamp(0.0, maxX),
                  (origin.dy + details.delta.dy / size.height).clamp(0.0, maxY),
                ),
              ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: diameter * 0.08,
                offset: Offset(0, diameter * 0.03),
              ),
            ],
          ),
          child: StickerAvatar(
            assetPath: stickerAssetPath,
            size: diameter,
            borderWidth: diameter * 0.045,
            showShadow: false,
          ),
        ),
      ),
    );
  }
}

List<Shadow> _textShadows(double unit) => [
  Shadow(
    color: Colors.black.withValues(alpha: 0.4),
    blurRadius: 1.2 * unit,
    offset: Offset(0, 0.2 * unit),
  ),
];

/// Véus escuros no topo (marca) e na base (números) para o texto branco ficar
/// legível sobre qualquer foto ou mapa claro.
class _Scrims extends StatelessWidget {
  const _Scrims();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x59000000), Color(0x00000000)],
              stops: [0, 0.22],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xA0000000)],
              stops: [0.45, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  final double unit;
  final ShareCardFonts fonts;

  const _Wordmark({required this.unit, required this.fonts});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8 * unit,
          height: 8 * unit,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 0.5 * unit),
            image: const DecorationImage(
              image: AssetImage('assets/images/logo.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 2 * unit),
        Text(
          'RUN4TREE',
          style: TextStyle(
            fontFamily: fonts.display,
            color: Colors.white,
            fontSize: 6.2 * unit,
            letterSpacing: 0.4 * unit,
            height: 1,
            shadows: _textShadows(unit),
          ),
        ),
      ],
    );
  }
}

class _StatsBlock extends StatelessWidget {
  final RunSessionEntity run;
  final double unit;
  final ShareCardFonts fonts;
  final List<LatLng> routePoints;

  const _StatsBlock({
    required this.run,
    required this.unit,
    required this.fonts,
    required this.routePoints,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final shadows = _textShadows(unit);
    final km = l10n.homeUnitKm.toUpperCase();

    final stats = [
      ('${run.distanceKm.toStringAsFixed(2)} $km', l10n.shareCardDistance),
      (
        formatStopwatchDuration(run.durationSeconds),
        l10n.exercisesDetailsDuration,
      ),
      if (run.exerciseType == 'bike')
        (
          '${run.averageSpeed.toStringAsFixed(1)} $km/H',
          l10n.exercisesDetailsAvgSpeed,
        )
      else
        ('${formatPace(run.pace)} /$km', l10n.exercisesDetailsPace),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.yMMMd(
                      locale,
                    ).format(run.createdAt).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 2.8 * unit,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5 * unit,
                      shadows: shadows,
                    ),
                  ),
                  SizedBox(height: 0.8 * unit),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      labelForExerciseType(
                        context,
                        run.exerciseType,
                      ).toUpperCase(),
                      style: TextStyle(
                        fontFamily: fonts.title,
                        color: Colors.white,
                        fontSize: 9 * unit,
                        height: 1.05,
                        shadows: shadows,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (routePoints.length >= 2)
              SizedBox(
                width: 26 * unit,
                height: 15 * unit,
                child: CustomPaint(
                  painter: RouteShapePainter(
                    points: routePoints,
                    color: Colors.white,
                    strokeWidth: 0.7 * unit,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 3.5 * unit),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) SizedBox(width: 5 * unit),
              Flexible(
                child: _Stat(
                  value: stats[i].$1,
                  label: stats[i].$2,
                  unit: unit,
                  fonts: fonts,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 4 * unit),
        _ImpactPill(
          text: run.treesEarned > 0
              ? l10n.shareCardSeeds(run.treesEarned)
              : l10n.shareCardTagline,
          unit: unit,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final double unit;
  final ShareCardFonts fonts;

  const _Stat({
    required this.value,
    required this.label,
    required this.unit,
    required this.fonts,
  });

  @override
  Widget build(BuildContext context) {
    final shadows = _textShadows(unit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: fonts.display,
              color: Colors.white,
              fontSize: 8.5 * unit,
              height: 1,
              letterSpacing: 0.2 * unit,
              shadows: shadows,
            ),
          ),
        ),
        SizedBox(height: 0.6 * unit),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 2.5 * unit,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.35 * unit,
              shadows: shadows,
            ),
          ),
        ),
      ],
    );
  }
}

/// Selo verde com o impacto da atividade — o que diferencia o Run4Tree de
/// qualquer outro app de corrida no feed.
class _ImpactPill extends StatelessWidget {
  final String text;
  final double unit;

  const _ImpactPill({required this.text, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3 * unit, vertical: 1.5 * unit),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10 * unit),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, color: Colors.white, size: 3.6 * unit),
          SizedBox(width: 1.4 * unit),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 2.9 * unit,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1 * unit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
