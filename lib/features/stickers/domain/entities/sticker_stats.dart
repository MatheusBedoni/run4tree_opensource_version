import '../../../runs/domain/entities/run_session_entity.dart';

/// Fotografia das métricas do usuário usada para avaliar os requisitos dos
/// adesivos. Derivada do histórico de corridas, do progresso de árvores e da
/// meta semanal do questionário de boas-vindas.
class StickerStats {
  /// Total de atividades concluídas.
  final int totalRuns;

  /// Distância somada de todas as atividades (km).
  final double totalDistanceKm;

  /// Maior distância em uma única atividade (km).
  final double longestRunKm;

  /// Dias consecutivos com pelo menos uma atividade.
  final int currentStreakDays;

  /// Árvores realmente plantadas via Tree-Nation.
  final int treesPlanted;

  /// Quantidade de semanas em que a meta semanal de km foi batida.
  final int weeklyGoalWeeksReached;

  /// Atividades iniciadas à noite (a partir das 20h ou antes das 5h).
  final int nightRuns;

  /// Tipos distintos de exercício já praticados ("run", "walk", "bike").
  final int distinctExerciseTypes;

  const StickerStats({
    required this.totalRuns,
    required this.totalDistanceKm,
    required this.longestRunKm,
    required this.currentStreakDays,
    required this.treesPlanted,
    required this.weeklyGoalWeeksReached,
    required this.nightRuns,
    required this.distinctExerciseTypes,
  });

  const StickerStats.empty()
    : totalRuns = 0,
      totalDistanceKm = 0,
      longestRunKm = 0,
      currentStreakDays = 0,
      treesPlanted = 0,
      weeklyGoalWeeksReached = 0,
      nightRuns = 0,
      distinctExerciseTypes = 0;

  /// Calcula as métricas a partir do histórico do usuário.
  ///
  /// [now] existe para os testes conseguirem fixar "hoje" ao verificar a
  /// sequência de dias.
  factory StickerStats.fromHistory({
    required List<RunSessionEntity> runs,
    required int treesPlanted,
    required double weeklyGoalKm,
    DateTime? now,
  }) {
    if (runs.isEmpty) {
      return StickerStats(
        totalRuns: 0,
        totalDistanceKm: 0,
        longestRunKm: 0,
        currentStreakDays: 0,
        treesPlanted: treesPlanted,
        weeklyGoalWeeksReached: 0,
        nightRuns: 0,
        distinctExerciseTypes: 0,
      );
    }

    var totalDistanceKm = 0.0;
    var longestRunKm = 0.0;
    var nightRuns = 0;
    final exerciseTypes = <String>{};

    for (final run in runs) {
      totalDistanceKm += run.distanceKm;
      if (run.distanceKm > longestRunKm) longestRunKm = run.distanceKm;
      if (_isNightRun(run)) nightRuns++;
      exerciseTypes.add(run.exerciseType);
    }

    return StickerStats(
      totalRuns: runs.length,
      totalDistanceKm: totalDistanceKm,
      longestRunKm: longestRunKm,
      currentStreakDays: _currentStreakDays(runs, now ?? DateTime.now()),
      treesPlanted: treesPlanted,
      weeklyGoalWeeksReached: _weeklyGoalWeeksReached(runs, weeklyGoalKm),
      nightRuns: nightRuns,
      distinctExerciseTypes: exerciseTypes.length,
    );
  }

  /// Atividade noturna: começou a partir das 20h ou antes das 5h.
  static bool _isNightRun(RunSessionEntity run) {
    if (run.isNight) return true;
    final hour = run.createdAt.hour;
    return hour >= 20 || hour < 5;
  }

  /// Dias consecutivos com pelo menos uma atividade.
  ///
  /// A contagem começa hoje; se ainda não houve atividade hoje, começa ontem —
  /// assim a sequência não zera no meio do dia corrente.
  static int _currentStreakDays(List<RunSessionEntity> runs, DateTime now) {
    final days = runs.map((run) => _dateOnly(run.createdAt)).toSet();
    if (days.isEmpty) return 0;

    final today = _dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime cursor;
    if (days.contains(today)) {
      cursor = today;
    } else if (days.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Semanas (segunda a domingo) em que a soma de km bateu a meta semanal.
  static int _weeklyGoalWeeksReached(
    List<RunSessionEntity> runs,
    double weeklyGoalKm,
  ) {
    if (weeklyGoalKm <= 0) return 0;

    final distanceByWeek = <DateTime, double>{};
    for (final run in runs) {
      final weekStart = _startOfWeek(run.createdAt);
      distanceByWeek[weekStart] =
          (distanceByWeek[weekStart] ?? 0) + run.distanceKm;
    }
    return distanceByWeek.values
        .where((distance) => distance >= weeklyGoalKm)
        .length;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _startOfWeek(DateTime date) {
    final day = _dateOnly(date);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
