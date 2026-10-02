import '../repositories/run_session_repository.dart';

/// Caso de uso: remove uma sessão de corrida pelo ID.
class DeleteRunUseCase {
  final RunSessionRepository _repository;

  const DeleteRunUseCase(this._repository);

  /// Executa o caso de uso.
  Future<void> call(int id) => _repository.deleteRun(id);
}
