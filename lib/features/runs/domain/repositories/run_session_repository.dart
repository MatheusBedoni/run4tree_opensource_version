import '../entities/run_session_entity.dart';

/// Contrato de repositório para sessões de corrida.
///
/// Define o que o domínio espera da camada de dados.
/// A implementação concreta fica na camada data — o domínio nunca a conhece.
abstract class RunSessionRepository {
  /// Salva uma sessão de corrida e retorna o ID inserido.
  Future<int> saveRun(RunSessionEntity run);

  /// Retorna todas as sessões salvas, ordenadas por data (mais recente primeiro).
  Future<List<RunSessionEntity>> getAllRuns();

  /// Retorna uma sessão pelo ID, ou null se não encontrada.
  Future<RunSessionEntity?> getRunById(int id);

  /// Remove uma sessão pelo ID.
  Future<void> deleteRun(int id);
}
