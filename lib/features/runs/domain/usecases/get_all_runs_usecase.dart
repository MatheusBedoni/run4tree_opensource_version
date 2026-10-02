import '../entities/run_session_entity.dart';
import '../repositories/run_session_repository.dart';

/// Caso de uso: retorna todas as sessões de corrida salvas.
class GetAllRunsUseCase {
  final RunSessionRepository _repository;

  const GetAllRunsUseCase(this._repository);

  /// Executa o caso de uso e retorna a lista de corridas.
  Future<List<RunSessionEntity>> call() => _repository.getAllRuns();
}
