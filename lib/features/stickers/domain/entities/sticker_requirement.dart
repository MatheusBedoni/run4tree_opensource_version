import 'sticker_stats.dart';

/// Tipos de conquista que desbloqueiam um adesivo.
///
/// Para criar um adesivo novo basta combinar um destes tipos com um alvo no
/// [StickerCatalog] — nenhuma outra camada precisa mudar. Tipos inéditos só
/// exigem um `case` novo em [StickerRequirement.currentValue] e um texto no
/// arquivo de tradução.
enum StickerRequirementType {
  /// Liberado desde o começo, sem exigência.
  free,

  /// Distância acumulada em km.
  totalDistanceKm,

  /// Distância em uma única atividade, em km.
  singleRunDistanceKm,

  /// Dias consecutivos com atividade.
  streakDays,

  /// Árvores plantadas de verdade.
  treesPlanted,

  /// Atividades concluídas.
  totalRuns,

  /// Semanas em que a meta semanal foi batida.
  weeklyGoalWeeks,

  /// Atividades noturnas.
  nightRuns,

  /// Tipos distintos de exercício praticados (caminhada, corrida, bike).
  exerciseVariety,
}

/// Regra de desbloqueio de um adesivo: um [type] e um [target] a alcançar.
class StickerRequirement {
  final StickerRequirementType type;

  /// Valor que precisa ser atingido. Para [StickerRequirementType.free] é 0.
  final double target;

  const StickerRequirement(this.type, this.target);

  const StickerRequirement.free()
    : type = StickerRequirementType.free,
      target = 0;

  /// Valor atual do usuário para este tipo de requisito.
  double currentValue(StickerStats stats) {
    switch (type) {
      case StickerRequirementType.free:
        return 0;
      case StickerRequirementType.totalDistanceKm:
        return stats.totalDistanceKm;
      case StickerRequirementType.singleRunDistanceKm:
        return stats.longestRunKm;
      case StickerRequirementType.streakDays:
        return stats.currentStreakDays.toDouble();
      case StickerRequirementType.treesPlanted:
        return stats.treesPlanted.toDouble();
      case StickerRequirementType.totalRuns:
        return stats.totalRuns.toDouble();
      case StickerRequirementType.weeklyGoalWeeks:
        return stats.weeklyGoalWeeksReached.toDouble();
      case StickerRequirementType.nightRuns:
        return stats.nightRuns.toDouble();
      case StickerRequirementType.exerciseVariety:
        return stats.distinctExerciseTypes.toDouble();
    }
  }

  bool isSatisfiedBy(StickerStats stats) {
    if (type == StickerRequirementType.free) return true;
    return currentValue(stats) >= target;
  }

  /// Progresso de 0.0 a 1.0 rumo ao desbloqueio.
  double progress(StickerStats stats) {
    if (type == StickerRequirementType.free) return 1;
    if (target <= 0) return 1;
    return (currentValue(stats) / target).clamp(0.0, 1.0);
  }
}
