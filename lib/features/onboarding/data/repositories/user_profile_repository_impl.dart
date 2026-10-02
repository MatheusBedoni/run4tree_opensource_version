import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_profile_repository.dart';

/// Implementação concreta do [UserProfileRepository].
///
/// Guarda as respostas do questionário de boas-vindas em uma única linha
/// (id fixo 1) na tabela [UserProfile] do Drift, seguindo o mesmo padrão do
/// [TreeGardenRepositoryImpl].
class UserProfileRepositoryImpl implements UserProfileRepository {
  static const int _rowId = 1;

  final AppDatabase _db;

  UserProfileRepositoryImpl({AppDatabase? db})
    : _db = db ?? AppDatabase.instance;

  @override
  Future<UserProfileEntity?> getUserProfile() async {
    final row = await (_db.select(
      _db.userProfile,
    )..where((t) => t.id.equals(_rowId))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Future<void> saveUserProfile(UserProfileEntity profile) async {
    // Preserva a data original do questionário em edições — só um insert
    // novo deixa o `createdAt` (default do Drift) definir a data atual.
    final existing = await (_db.select(
      _db.userProfile,
    )..where((t) => t.id.equals(_rowId))).getSingleOrNull();

    await _db
        .into(_db.userProfile)
        .insertOnConflictUpdate(
          UserProfileCompanion(
            id: const Value(_rowId),
            name: Value(profile.name),
            age: Value(profile.age),
            weeklyGoalKm: Value(profile.weeklyGoalKm),
            weightKg: Value(profile.weightKg),
            heightCm: Value(profile.heightCm),
            createdAt: existing != null
                ? Value(existing.createdAt)
                : const Value.absent(),
          ),
        );
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final row = await (_db.select(
      _db.userProfile,
    )..where((t) => t.id.equals(_rowId))).getSingleOrNull();
    return row != null;
  }

  UserProfileEntity _toEntity(UserProfileData row) => UserProfileEntity(
    name: row.name,
    age: row.age,
    weeklyGoalKm: row.weeklyGoalKm,
    weightKg: row.weightKg,
    heightCm: row.heightCm,
    createdAt: row.createdAt,
  );
}
