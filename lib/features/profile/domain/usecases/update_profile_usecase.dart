import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository _repository;

  const UpdateProfileUseCase(this._repository);

  Future<void> call({
    required String name,
    required int age,
    required double weightKg,
    required double heightCm,
    required double weeklyGoalKm,
  }) => _repository.updateProfile(
    name: name,
    age: age,
    weightKg: weightKg,
    heightCm: heightCm,
    weeklyGoalKm: weeklyGoalKm,
  );
}
