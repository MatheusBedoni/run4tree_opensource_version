import 'package:flutter/foundation.dart';
import '../../../garden/domain/entities/tree_progress_entity.dart';
import '../../domain/entities/run_stats_entity.dart';
import '../../domain/usecases/get_run_stats_usecase.dart';

/// Controller da HomePage seguindo o padrão ChangeNotifier.
///
/// Gerencia o ciclo de vida do estado (loading → sucesso → erro) e expõe
/// os dados para a UI via [ListenableBuilder] — sem necessidade de Provider
/// ou Bloc para este escopo inicial.
class HomeController extends ChangeNotifier {
  final GetRunStatsUseCase _getRunStatsUseCase;

  HomeController(this._getRunStatsUseCase);

  // ─── Estado ────────────────────────────────────────────────────────────────

  RunStatsEntity? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  RunStatsEntity? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Ações ─────────────────────────────────────────────────────────────────

  /// Carrega as estatísticas da sessão atual.
  Future<void> loadStats() async {
    _setLoading(true);
    try {
      _stats = await _getRunStatsUseCase();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Não foi possível carregar os dados. Tente novamente.';
      debugPrint('HomeController.loadStats error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Força um reload dos stats (ex: pull-to-refresh).
  Future<void> refreshStats() => loadStats();

  /// Aplica um progresso de árvore atualizado (após um anúncio creditar
  /// receita) sem precisar refazer o fetch completo de stats.
  void applyTreeProgress(TreeProgressEntity progress) {
    final current = _stats;
    if (current == null) {
      // Stats ainda não carregados: o progresso creditado no banco é
      // descartado da UI e o anel continua mostrando o valor antigo.
      debugPrint(
        'HomeController.applyTreeProgress ignorado: stats ainda não carregados '
        '(árvores=${progress.treesPlanted}, '
        '${(progress.progressPercent * 100).toStringAsFixed(1)}%)',
      );
      return;
    }
    debugPrint(
      'HomeController.applyTreeProgress: '
      '${(current.progressPercent * 100).toStringAsFixed(1)}% -> '
      '${(progress.progressPercent * 100).toStringAsFixed(1)}% | '
      'árvores ${current.treesPlanted} -> ${progress.treesPlanted}',
    );
    _stats = current.copyWith(
      treesPlanted: progress.treesPlanted,
      progressPercent: progress.progressPercent,
    );
    notifyListeners();
  }

  // ─── Helpers privados ──────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
