import '../models/exercise_model.dart';

abstract class ExerciseLocalDataSource {
  Future<void> cacheExercise(ExerciseModel exercise);
  Future<List<ExerciseModel>> getCachedExercises();
  Future<void> deleteExercise(String id);
}
