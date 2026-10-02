import '../entities/run_stats_entity.dart';
import '../repositories/home_repository.dart';

/// Caso de uso: obtém as estatísticas da sessão atual.
///
/// Seguindo Clean Architecture, este use case encapsula a regra de negócio
/// de buscar dados de run — a presentation só interage com esta classe,
/// nunca com o repositório diretamente.
class GetRunStatsUseCase {
  final HomeRepository _repository;

  const GetRunStatsUseCase(this._repository);

  /// Executa o caso de uso e retorna [RunStatsEntity].
  Future<RunStatsEntity> call() => _repository.getRunStats();
}
