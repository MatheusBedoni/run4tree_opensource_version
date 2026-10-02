import '../entities/run_stats_entity.dart';

/// Contrato de repositório: define o que o domínio espera da camada de dados.
/// A implementação real fica na camada data — o domínio nunca a conhece.
abstract class HomeRepository {
  /// Retorna o snapshot de estatísticas da sessão atual do usuário.
  Future<RunStatsEntity> getRunStats();
}
