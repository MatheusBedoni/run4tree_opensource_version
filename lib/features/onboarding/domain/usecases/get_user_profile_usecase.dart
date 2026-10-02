import '../entities/user_profile_entity.dart';
import '../repositories/user_profile_repository.dart';

class GetUserProfileUseCase {
  final UserProfileRepository _repository;

  const GetUserProfileUseCase(this._repository);

  Future<UserProfileEntity?> call() => _repository.getUserProfile();
}
