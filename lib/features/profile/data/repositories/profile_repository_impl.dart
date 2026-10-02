import '../../../../core/database/app_database.dart';
import '../../../garden/data/repositories/tree_garden_repository_impl.dart';
import '../../../garden/domain/repositories/tree_garden_repository.dart';
import '../../../onboarding/data/repositories/user_profile_repository_impl.dart';
import '../../../onboarding/domain/entities/user_profile_entity.dart';
import '../../../onboarding/domain/repositories/user_profile_repository.dart';
import '../../../runs/data/datasources/run_session_local_datasource_impl.dart';
import '../../../runs/data/repositories/run_session_repository_impl.dart';
import '../../../runs/domain/repositories/run_session_repository.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

/// Implementação concreta do [ProfileRepository].
///
/// Não guarda dados próprios: combina o questionário de boas-vindas
/// ([UserProfileRepository]) com o histórico de corridas ([RunSessionRepository])
/// e o progresso de árvores ([TreeGardenRepository]) para montar um
/// [ProfileEntity] sempre atualizado.
class ProfileRepositoryImpl implements ProfileRepository {
  final UserProfileRepository _userProfileRepository;
  final RunSessionRepository _runSessionRepository;
  final TreeGardenRepository _treeGardenRepository;

  ProfileRepositoryImpl({
    UserProfileRepository? userProfileRepository,
    RunSessionRepository? runSessionRepository,
    TreeGardenRepository? treeGardenRepository,
  }) : _userProfileRepository =
           userProfileRepository ?? UserProfileRepositoryImpl(),
       _runSessionRepository =
           runSessionRepository ??
           RunSessionRepositoryImpl(
             RunSessionLocalDataSourceImpl(AppDatabase.instance),
           ),
       _treeGardenRepository =
           treeGardenRepository ?? TreeGardenRepositoryImpl();

  @override
  Future<ProfileEntity?> getProfile() async {
    final userProfile = await _userProfileRepository.getUserProfile();
    if (userProfile == null) return null;

    final runs = await _runSessionRepository.getAllRuns();
    final treeProgress = await _treeGardenRepository.getProgress();

    final totalDistanceKm = runs.fold(0.0, (sum, run) => sum + run.distanceKm);

    final weekStart = _startOfWeek(DateTime.now());
    final weeklyDistanceKm = runs
        .where((run) => !run.createdAt.isBefore(weekStart))
        .fold(0.0, (sum, run) => sum + run.distanceKm);

    return ProfileEntity(
      name: userProfile.name,
      age: userProfile.age,
      weightKg: userProfile.weightKg,
      heightCm: userProfile.heightCm,
      weeklyGoalKm: userProfile.weeklyGoalKm,
      treesPlanted: treeProgress.treesPlanted,
      totalRuns: runs.length,
      totalDistanceKm: totalDistanceKm,
      weeklyDistanceKm: weeklyDistanceKm,
      memberSince: userProfile.createdAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> updateProfile({
    required String name,
    required int age,
    required double weightKg,
    required double heightCm,
    required double weeklyGoalKm,
  }) {
    return _userProfileRepository.saveUserProfile(
      UserProfileEntity(
        name: name,
        age: age,
        weeklyGoalKm: weeklyGoalKm,
        weightKg: weightKg,
        heightCm: heightCm,
      ),
    );
  }

  /// Início da semana corrente (segunda-feira, 00:00).
  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
