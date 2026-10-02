import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/run_session_entity.dart';

/// Mapper para converter entre tipos do domínio e tipos do Drift.
///
/// Garante que a camada domain nunca conhece detalhes do Drift
/// e vice-versa — cada camada trabalha com seus próprios tipos.
class RunSessionMapper {
  const RunSessionMapper._();

  /// Converte um [RunSession] (gerado pelo Drift) → [RunSessionEntity] (domínio).
  static RunSessionEntity toEntity(RunSession row) {
    return RunSessionEntity(
      id: row.id,
      durationSeconds: row.durationSeconds,
      distanceKm: row.distanceKm,
      calories: row.calories,
      averageSpeed: row.averageSpeed,
      maxSpeed: row.maxSpeed,
      pace: row.pace,
      polyline: row.polyline,
      temperature: row.temperature,
      isNight: row.isNight,
      treesEarned: row.treesEarned,
      exerciseType: row.exerciseType,
      createdAt: row.createdAt,
    );
  }

  /// Converte um [RunSessionEntity] (domínio) → [RunSessionsCompanion] (Drift insert).
  static RunSessionsCompanion toCompanion(RunSessionEntity entity) {
    return RunSessionsCompanion(
      durationSeconds: Value(entity.durationSeconds),
      distanceKm: Value(entity.distanceKm),
      calories: Value(entity.calories),
      averageSpeed: Value(entity.averageSpeed),
      maxSpeed: Value(entity.maxSpeed),
      pace: Value(entity.pace),
      polyline: Value(entity.polyline),
      temperature: Value(entity.temperature),
      isNight: Value(entity.isNight),
      treesEarned: Value(entity.treesEarned),
      exerciseType: Value(entity.exerciseType),
      createdAt: Value(entity.createdAt),
    );
  }
}
