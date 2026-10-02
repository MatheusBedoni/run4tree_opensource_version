import '../../../../core/database/app_database.dart';

/// Contrato do datasource local para sessões de corrida.
///
/// Define as operações CRUD usando tipos gerados pelo Drift.
abstract class RunSessionLocalDataSource {
  /// Insere uma nova sessão e retorna o ID gerado.
  Future<int> insertRun(RunSessionsCompanion run);

  /// Retorna todas as sessões, mais recente primeiro.
  Future<List<RunSession>> getAllRuns();

  /// Retorna uma sessão pelo ID, ou null se não encontrada.
  Future<RunSession?> getRunById(int id);

  /// Remove uma sessão pelo ID.
  Future<void> deleteRun(int id);
}
