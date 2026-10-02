import '../entities/user_profile_entity.dart';
import '../repositories/user_profile_repository.dart';

class SaveUserProfileUseCase {
  final UserProfileRepository _repository;

  const SaveUserProfileUseCase(this._repository);

  Future<void> call(UserProfileEntity profile) =>
      _repository.saveUserProfile(profile);
}
