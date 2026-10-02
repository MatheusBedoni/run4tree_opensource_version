import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Formatadores e mapeamentos compartilhados entre a ExercisesPage e os
/// widgets de recordes/estatísticas, para que rótulos e ícones de modalidade
/// não divirjam entre as seções.

IconData iconForExerciseType(String exerciseType) {
  switch (exerciseType) {
    case 'bike':
      return Icons.directions_bike_rounded;
    case 'walk':
      return Icons.directions_walk_rounded;
    case 'run':
    default:
      return Icons.directions_run_rounded;
  }
}

String labelForExerciseType(BuildContext context, String exerciseType) {
  final l10n = AppLocalizations.of(context)!;
  switch (exerciseType) {
    case 'bike':
      return l10n.exercisesLabelBike;
    case 'walk':
      return l10n.exercisesLabelWalk;
    case 'run':
    default:
      return l10n.exercisesLabelRun;
  }
}

/// Duração compacta usada nos cards do histórico: `1h05m` ou `05:32`.
String formatCompactDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '${h}h${m.toString().padLeft(2, '0')}m';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Duração completa `HH:MM:SS`, usada no card de recorde de maior duração.
String formatClockDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return '${h.toString().padLeft(2, '0')}:'
      '${m.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}';
}

/// Cronômetro: `01:16:49` a partir de uma hora, `25:10` abaixo disso.
String formatStopwatchDuration(int seconds) {
  return seconds >= 3600
      ? formatClockDuration(seconds)
      : formatCompactDuration(seconds);
}

/// Ritmo em min/km no formato `05:24`. Atividades sem distância têm ritmo
/// infinito e viram `--:--`.
String formatPace(double paceMinPerKm) {
  if (!paceMinPerKm.isFinite) return '--:--';
  final mins = paceMinPerKm.floor();
  final secs = ((paceMinPerKm - mins) * 60).round();
  return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}
