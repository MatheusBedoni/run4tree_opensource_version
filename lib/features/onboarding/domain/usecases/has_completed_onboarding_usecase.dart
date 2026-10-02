import '../repositories/user_profile_repository.dart';

class HasCompletedOnboardingUseCase {
  final UserProfileRepository _repository;

  const HasCompletedOnboardingUseCase(this._repository);

  Future<bool> call() => _repository.hasCompletedOnboarding();
}
