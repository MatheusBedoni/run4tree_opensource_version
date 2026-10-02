import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../garden/domain/entities/tree_progress_entity.dart';

/// Pílula compacta exibida junto ao banner durante a corrida.
///
/// O banner credita receita silenciosamente a cada recarga — sem isso, a
/// única parte do loop anúncio → sementes → árvore real que o usuário não
/// enxerga. A pílula mostra o saldo de sementes e dispara um "+1 seed"
/// flutuante sempre que o crédito faz o contador subir.
class RunSeedTicker extends StatefulWidget {
  /// Sementes acumuladas para a próxima árvore (0 a [total]).
  final int seeds;

  /// Total de árvores já plantadas — usado para detectar quando o contador
  /// "vira" e uma árvore é fechada.
  final int treesPlanted;

  final int total;

  const RunSeedTicker({
    super.key,
    required this.seeds,
    required this.treesPlanted,
    this.total = TreeProgressEntity.seedsPerTree,
  });

  @override
  State<RunSeedTicker> createState() => _RunSeedTickerState();
}

class _RunSeedTickerState extends State<RunSeedTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Quantas sementes o último crédito rendeu (0 quando nada a mostrar).
  int _gainedSeeds = 0;

  /// Verdadeiro quando o último crédito fechou uma árvore.
  bool _plantedTree = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(RunSeedTicker old) {
    super.didUpdateWidget(old);

    final treeDelta = widget.treesPlanted - old.treesPlanted;
    if (treeDelta > 0) {
      // Fechou a árvore: o contador de sementes reinicia, então o ganho é
      // o que faltava para completar mais o resto que sobrou.
      _plantedTree = true;
      _gainedSeeds = (widget.total - old.seeds) + widget.seeds;
      _ctrl.forward(from: 0);
      return;
    }

    final seedDelta = widget.seeds - old.seeds;
    if (seedDelta > 0) {
      _plantedTree = false;
      _gainedSeeds = seedDelta;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _buildPill(l10n),
        // Sobe e some por cima da pílula quando o banner credita.
        Positioned(
          bottom: 18,
          child: IgnorePointer(child: _buildFloatingBadge(l10n)),
        ),
      ],
    );
  }

  Widget _buildPill(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // Um "pop" curto no começo da animação chama a atenção sem distrair.
        final pop = Curves.easeOut.transform(
          (1 - (_ctrl.value / 0.25)).clamp(0.0, 1.0),
        );
        return Transform.scale(scale: 1 + 0.12 * pop, child: child);
      },
      child: Semantics(
        label: l10n.homeRunAdSeedsToNextTree(widget.seeds, widget.total),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.eco_rounded,
                size: 14,
                color: AppColors.progressGreen,
              ),
              const SizedBox(width: 5),
              Text(
                '${widget.seeds}/${widget.total}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBadge(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        if (t == 0 || t == 1 || _gainedSeeds <= 0) {
          return const SizedBox.shrink();
        }

        // Entra rápido, segura no meio e some subindo.
        final opacity = t < 0.15
            ? t / 0.15
            : t > 0.7
            ? (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0)
            : 1.0;
        final offsetY = -18 * Curves.easeOut.transform(t);

        final color = _plantedTree
            ? AppColors.accentOrange
            : AppColors.progressGreen;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _plantedTree ? Icons.park_rounded : Icons.eco_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _plantedTree
                        ? l10n.homeRunTreeEarnedBadge
                        : l10n.homeRunAdSeedsGainedBadge(_gainedSeeds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
