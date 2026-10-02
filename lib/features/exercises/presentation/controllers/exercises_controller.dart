import 'package:flutter/foundation.dart';

import '../../../profile/domain/entities/profile_entity.dart';
import '../../../profile/domain/usecases/get_profile_usecase.dart';
import '../../../runs/domain/entities/run_session_entity.dart';
import '../../../runs/domain/usecases/delete_run_usecase.dart';
import '../../../runs/domain/usecases/get_all_runs_usecase.dart';
import '../../domain/entities/exercise_stats.dart';

/// Quantidade de meses exibidos no gráfico de estatísticas.
const int kStatsMonthWindow = 12;

/// Controller da ExercisesPage seguindo o padrão ChangeNotifier.
///
/// Carrega o histórico de corridas salvas no Drift e o perfil do usuário, e
/// expõe o estado (loading → sucesso → erro) junto das métricas derivadas
/// (recordes, série mensal e totais) para a UI via [ListenableBuilder].
class ExercisesController extends ChangeNotifier {
  final GetAllRunsUseCase _getAllRunsUseCase;
  final DeleteRunUseCase _deleteRunUseCase;
  final GetProfileUseCase _getProfileUseCase;

  ExercisesController(
    this._getAllRunsUseCase,
    this._deleteRunUseCase,
    this._getProfileUseCase,
  );

  // ─── Estado ────────────────────────────────────────────────────────────────

  List<RunSessionEntity> _runs = [];
  ProfileEntity? _profile;
  bool _isLoading = false;
  bool _hasLoadError = false;

  /// Tipo de exercício selecionado no filtro de estatísticas.
  /// `null` representa "todos".
  String? _statsFilter;

  List<RunSessionEntity> get runs => _runs;
  ProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;
  String? get statsFilter => _statsFilter;

  // ─── Métricas derivadas ────────────────────────────────────────────────────

  /// Tipos de exercício que o usuário realmente registrou, na ordem canônica.
  /// Usado para montar os chips de filtro sem oferecer opções vazias.
  List<String> get availableExerciseTypes {
    const canonicalOrder = ['run', 'walk', 'bike'];
    final registered = _runs.map((run) => run.exerciseType).toSet();
    return canonicalOrder.where(registered.contains).toList();
  }

  /// Melhores marcas do usuário considerando todo o histórico (sem filtro),
  /// já que um recorde pessoal vale para qualquer modalidade.
  ///
  /// Só entram métricas com valor válido — uma corrida sem distância ou sem
  /// ritmo não deve ocupar um card de recorde.
  List<ExerciseRecord> get records {
    if (_runs.isEmpty) return const [];

    final result = <ExerciseRecord>[];

    void addBest(
      ExerciseRecordType type,
      double Function(RunSessionEntity run) metric, {
      bool lowerIsBetter = false,
    }) {
      RunSessionEntity? best;
      for (final run in _runs) {
        final value = metric(run);
        if (value <= 0) continue;
        if (best == null ||
            (lowerIsBetter ? value < metric(best) : value > metric(best))) {
          best = run;
        }
      }
      if (best != null) {
        result.add(ExerciseRecord(type: type, run: best));
      }
    }

    addBest(ExerciseRecordType.longestDistance, (run) => run.distanceKm);
    addBest(
      ExerciseRecordType.longestDuration,
      (run) => run.durationSeconds.toDouble(),
    );
    addBest(ExerciseRecordType.mostCalories, (run) => run.calories);
    addBest(
      ExerciseRecordType.bestPace,
      (run) => run.pace,
      lowerIsBetter: true,
    );
    addBest(ExerciseRecordType.topSpeed, (run) => run.maxSpeed);

    return result;
  }

  /// Série dos últimos [kStatsMonthWindow] meses (mais antigo → mais recente),
  /// respeitando o filtro de modalidade. Meses sem atividade vêm zerados para
  /// que o gráfico mantenha as 12 colunas.
  List<MonthlyStat> get monthlyStats {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final buckets = <DateTime, List<RunSessionEntity>>{};

    for (var i = kStatsMonthWindow - 1; i >= 0; i--) {
      buckets[DateTime(currentMonth.year, currentMonth.month - i)] = [];
    }

    for (final run in _filteredRuns) {
      final key = DateTime(run.createdAt.year, run.createdAt.month);
      buckets[key]?.add(run);
    }

    return buckets.entries.map((entry) {
      return MonthlyStat(
        month: entry.key,
        distanceKm: entry.value.fold(0.0, (sum, run) => sum + run.distanceKm),
        durationSeconds: entry.value.fold(
          0,
          (sum, run) => sum + run.durationSeconds,
        ),
        activityCount: entry.value.length,
      );
    }).toList();
  }

  /// Totais do período mostrado no gráfico, respeitando o filtro atual.
  ExerciseSummary get summary {
    final months = monthlyStats;
    if (months.isEmpty) return ExerciseSummary.empty;

    return ExerciseSummary(
      activityCount: months.fold(0, (sum, m) => sum + m.activityCount),
      totalDurationSeconds: months.fold(0, (sum, m) => sum + m.durationSeconds),
      totalDistanceKm: months.fold(0.0, (sum, m) => sum + m.distanceKm),
    );
  }

  List<RunSessionEntity> get _filteredRuns {
    final filter = _statsFilter;
    if (filter == null) return _runs;
    return _runs.where((run) => run.exerciseType == filter).toList();
  }

  // ─── Ações ─────────────────────────────────────────────────────────────────

  /// Carrega o histórico de corridas e o perfil do usuário.
  Future<void> loadRuns() async {
    _setLoading(true);
    try {
      _runs = await _getAllRunsUseCase();
      _hasLoadError = false;
    } catch (e) {
      _hasLoadError = true;
      debugPrint('ExercisesController.loadRuns error: $e');
    }

    // O perfil alimenta apenas o card de meta semanal: uma falha aqui não
    // invalida o histórico já carregado.
    try {
      _profile = await _getProfileUseCase();
    } catch (e) {
      debugPrint('ExercisesController.loadProfile error: $e');
    }

    _setLoading(false);
  }

  /// Força um reload das corridas (ex: pull-to-refresh).
  Future<void> refreshRuns() => loadRuns();

  /// Troca o filtro de modalidade das estatísticas (`null` = todos).
  void selectStatsFilter(String? exerciseType) {
    if (_statsFilter == exerciseType) return;
    _statsFilter = exerciseType;
    notifyListeners();
  }

  /// Remove uma corrida pelo ID e atualiza a lista local.
  Future<void> deleteRun(int id) async {
    final previous = _runs;
    _runs = _runs.where((run) => run.id != id).toList();
    notifyListeners();
    try {
      await _deleteRunUseCase(id);
    } catch (e) {
      _runs = previous;
      debugPrint('ExercisesController.deleteRun error: $e');
      notifyListeners();
    }
  }

  // ─── Helpers privados ──────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
