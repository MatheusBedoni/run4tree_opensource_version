import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/sticker_definition.dart';
import '../../domain/entities/sticker_entity.dart';
import '../../domain/entities/sticker_requirement.dart';

/// Textos localizados dos adesivos.
///
/// Ficam fora do catálogo de propósito: o domínio não conhece `AppLocalizations`.
/// Adesivos novos sem uma chave `stickerName<id>` caem no nome genérico, então
/// o app nunca quebra ao crescer a coleção.
String stickerName(AppLocalizations l10n, StickerDefinition definition) {
  switch (definition.id) {
    case '1':
      return l10n.stickerName1;
    case '2':
      return l10n.stickerName2;
    case '3':
      return l10n.stickerName3;
    case '4':
      return l10n.stickerName4;
    case '5':
      return l10n.stickerName5;
    case '6':
      return l10n.stickerName6;
    case '7':
      return l10n.stickerName7;
    case '8':
      return l10n.stickerName8;
    case '9':
      return l10n.stickerName9;
    case '10':
      return l10n.stickerName10;
    case '11':
      return l10n.stickerName11;
    case '12':
      return l10n.stickerName12;
    case '13':
      return l10n.stickerName13;
    case '14':
      return l10n.stickerName14;
    default:
      return l10n.stickerNameFallback(definition.id);
  }
}

/// Frase que descreve como conquistar o adesivo ("Corra 10 km no total").
String stickerRequirementLabel(
  AppLocalizations l10n,
  StickerRequirement requirement,
) {
  final target = requirement.target;
  switch (requirement.type) {
    case StickerRequirementType.free:
      return l10n.stickerRequirementFree;
    case StickerRequirementType.totalDistanceKm:
      return l10n.stickerRequirementTotalDistance(_formatNumber(target));
    case StickerRequirementType.singleRunDistanceKm:
      return l10n.stickerRequirementSingleRun(_formatNumber(target));
    case StickerRequirementType.streakDays:
      return l10n.stickerRequirementStreak(target.round());
    case StickerRequirementType.treesPlanted:
      return l10n.stickerRequirementTrees(target.round());
    case StickerRequirementType.totalRuns:
      return l10n.stickerRequirementRuns(target.round());
    case StickerRequirementType.weeklyGoalWeeks:
      return l10n.stickerRequirementWeeklyGoal(target.round());
    case StickerRequirementType.nightRuns:
      return l10n.stickerRequirementNightRuns(target.round());
    case StickerRequirementType.exerciseVariety:
      return l10n.stickerRequirementVariety;
  }
}

/// Contador de progresso do adesivo bloqueado ("7.4 / 10 km").
String stickerProgressLabel(AppLocalizations l10n, StickerEntity sticker) {
  final requirement = sticker.requirement;
  final target = _formatNumber(requirement.target);

  switch (requirement.type) {
    case StickerRequirementType.free:
      return '';
    case StickerRequirementType.totalDistanceKm:
    case StickerRequirementType.singleRunDistanceKm:
      final current = sticker.currentValue
          .clamp(0.0, requirement.target)
          .toStringAsFixed(1);
      return '$current / $target ${l10n.homeUnitKm}';
    default:
      final current = sticker.currentValue
          .clamp(0.0, requirement.target)
          .round();
      return '$current / $target';
  }
}

/// Mostra "10" em vez de "10.0", mas mantém "2.5" quando houver decimal.
String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}
