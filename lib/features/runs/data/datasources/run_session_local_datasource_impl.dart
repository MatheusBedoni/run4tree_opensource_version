import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import 'run_session_local_datasource.dart';

/// Implementação concreta do [RunSessionLocalDataSource] usando Drift.
///
/// Recebe a instância do [AppDatabase] e executa as queries tipadas.
class RunSessionLocalDataSourceImpl implements RunSessionLocalDataSource {
  final AppDatabase _db;

  const RunSessionLocalDataSourceImpl(this._db);

  @override
  Future<int> insertRun(RunSessionsCompanion run) async {
    return await _db.into(_db.runSessions).insert(run);
  }

  @override
  Future<List<RunSession>> getAllRuns() async {
    return await (_db.select(_db.runSessions)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  @override
  Future<RunSession?> getRunById(int id) async {
    return await (_db.select(
      _db.runSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<void> deleteRun(int id) async {
    await (_db.delete(_db.runSessions)..where((t) => t.id.equals(id))).go();
  }
}
