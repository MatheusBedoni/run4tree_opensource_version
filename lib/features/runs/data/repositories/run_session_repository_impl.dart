import '../../domain/entities/run_session_entity.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../datasources/run_session_local_datasource.dart';
import '../models/run_session_mapper.dart';

/// Implementação concreta do [RunSessionRepository].
///
/// Orquestra o datasource local e faz o mapping entre tipos
/// do Drift e entidades do domínio via [RunSessionMapper].
class RunSessionRepositoryImpl implements RunSessionRepository {
  final RunSessionLocalDataSource _localDataSource;

  const RunSessionRepositoryImpl(this._localDataSource);

  @override
  Future<int> saveRun(RunSessionEntity run) {
    final companion = RunSessionMapper.toCompanion(run);
    return _localDataSource.insertRun(companion);
  }

  @override
  Future<List<RunSessionEntity>> getAllRuns() async {
    final rows = await _localDataSource.getAllRuns();
    return rows.map(RunSessionMapper.toEntity).toList();
  }

  @override
  Future<RunSessionEntity?> getRunById(int id) async {
    final row = await _localDataSource.getRunById(id);
    return row != null ? RunSessionMapper.toEntity(row) : null;
  }

  @override
  Future<void> deleteRun(int id) => _localDataSource.deleteRun(id);
}
