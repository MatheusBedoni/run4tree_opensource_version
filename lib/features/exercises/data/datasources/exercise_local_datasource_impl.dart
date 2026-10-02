import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/exercise_model.dart';
import 'exercise_local_datasource.dart';

/// Implementação do [ExerciseLocalDataSource] usando Drift.
///
/// Substitui a versão anterior baseada em sqflite.
class ExerciseLocalDataSourceImpl implements ExerciseLocalDataSource {
  final AppDatabase _db;

  const ExerciseLocalDataSourceImpl(this._db);

  @override
  Future<void> cacheExercise(ExerciseModel exercise) async {
    await _db
        .into(_db.exercises)
        .insertOnConflictUpdate(
          ExercisesCompanion(
            id: Value(exercise.id),
            name: Value(exercise.name),
            description: Value(exercise.description),
            category: Value(exercise.category),
            durationInMinutes: Value(exercise.durationInMinutes),
            caloriesBurned: Value(exercise.caloriesBurned),
          ),
        );
  }

  @override
  Future<List<ExerciseModel>> getCachedExercises() async {
    final rows = await _db.select(_db.exercises).get();
    return rows
        .map(
          (row) => ExerciseModel(
            id: row.id,
            name: row.name,
            description: row.description,
            category: row.category,
            durationInMinutes: row.durationInMinutes,
            caloriesBurned: row.caloriesBurned,
          ),
        )
        .toList();
  }

  @override
  Future<void> deleteExercise(String id) async {
    await (_db.delete(_db.exercises)..where((t) => t.id.equals(id))).go();
  }
}
