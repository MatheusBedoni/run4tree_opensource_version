import '../entities/user_profile_entity.dart';

abstract class UserProfileRepository {
  /// Retorna o perfil salvo, ou `null` se o usuário ainda não respondeu o
  /// questionário de boas-vindas.
  Future<UserProfileEntity?> getUserProfile();

  Future<void> saveUserProfile(UserProfileEntity profile);

  Future<bool> hasCompletedOnboarding();
}
