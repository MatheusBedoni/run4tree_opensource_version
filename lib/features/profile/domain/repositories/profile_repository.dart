import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  /// Retorna o perfil calculado, ou `null` se o usuário ainda não completou
  /// o questionário de boas-vindas.
  Future<ProfileEntity?> getProfile();

  Future<void> updateProfile({
    required String name,
    required int age,
    required double weightKg,
    required double heightCm,
    required double weeklyGoalKm,
  });
}
