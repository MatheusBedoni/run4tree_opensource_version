import '../../../runs/domain/entities/run_session_entity.dart';

/// Métricas em que um recorde pessoal pode ser batido.
enum ExerciseRecordType {
  longestDistance,
  longestDuration,
  mostCalories,
  bestPace,
  topSpeed,
}

/// Melhor marca do usuário em uma [ExerciseRecordType].
///
/// Guarda a sessão que detém o recorde para que a UI possa mostrar o tipo de
/// exercício (corrida, caminhada, bike) e navegar até os detalhes.
class ExerciseRecord {
  final ExerciseRecordType type;
  final RunSessionEntity run;

  const ExerciseRecord({required this.type, required this.run});

  /// Valor bruto do recorde, na unidade natural da métrica.
  double get value {
    switch (type) {
      case ExerciseRecordType.longestDistance:
        return run.distanceKm;
      case ExerciseRecordType.longestDuration:
        return run.durationSeconds.toDouble();
      case ExerciseRecordType.mostCalories:
        return run.calories;
      case ExerciseRecordType.bestPace:
        return run.pace;
      case ExerciseRecordType.topSpeed:
        return run.maxSpeed;
    }
  }
}

/// Agregado de um mês do gráfico de estatísticas.
class MonthlyStat {
  /// Primeiro dia do mês representado.
  final DateTime month;
  final double distanceKm;
  final int durationSeconds;
  final int activityCount;

  const MonthlyStat({
    required this.month,
    required this.distanceKm,
    required this.durationSeconds,
    required this.activityCount,
  });
}

/// Totais consolidados do período mostrado nas estatísticas.
class ExerciseSummary {
  final int activityCount;
  final int totalDurationSeconds;
  final double totalDistanceKm;

  const ExerciseSummary({
    required this.activityCount,
    required this.totalDurationSeconds,
    required this.totalDistanceKm,
  });

  static const empty = ExerciseSummary(
    activityCount: 0,
    totalDurationSeconds: 0,
    totalDistanceKm: 0,
  );
}
