import '../entities/run_session_entity.dart';
import '../repositories/run_session_repository.dart';

/// Caso de uso: salva uma sessão de corrida concluída.
///
/// Recebe a entidade com os dados da corrida e delega
/// a persistência para o repositório.
class SaveRunUseCase {
  final RunSessionRepository _repository;

  const SaveRunUseCase(this._repository);

  /// Executa o caso de uso e retorna o ID da corrida salva.
  Future<int> call(RunSessionEntity run) => _repository.saveRun(run);
}
