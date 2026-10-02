import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile_entity.dart';
import '../../domain/usecases/save_user_profile_usecase.dart';

/// Controller do questionário de boas-vindas (step-by-step).
///
/// Mantém os valores digitados em cada etapa e só persiste tudo de uma vez
/// ao final, via [SaveUserProfileUseCase].
class OnboardingController extends ChangeNotifier {
  final SaveUserProfileUseCase _saveUserProfileUseCase;

  OnboardingController(this._saveUserProfileUseCase);

  static const int stepCount = 4;

  int _currentStep = 0;
  String name = '';
  int? age;
  double? weightKg;
  double? heightCm;
  double? weeklyGoalKm;

  bool _isSaving = false;
  bool hasError = false;

  int get currentStep => _currentStep;
  bool get isSaving => _isSaving;
  bool get isLastStep => _currentStep == stepCount - 1;

  bool get canAdvance {
    switch (_currentStep) {
      case 0:
        return name.trim().isNotEmpty;
      case 1:
        return age != null && age! > 0 && age! < 120;
      case 2:
        return weightKg != null &&
            weightKg! > 0 &&
            heightCm != null &&
            heightCm! > 0;
      case 3:
        return weeklyGoalKm != null && weeklyGoalKm! > 0;
      default:
        return false;
    }
  }

  void updateName(String value) {
    name = value;
    notifyListeners();
  }

  void updateAge(String value) {
    age = int.tryParse(value);
    notifyListeners();
  }

  void updateWeight(String value) {
    weightKg = double.tryParse(value.replaceAll(',', '.'));
    notifyListeners();
  }

  void updateHeight(String value) {
    heightCm = double.tryParse(value.replaceAll(',', '.'));
    notifyListeners();
  }

  void updateWeeklyGoal(String value) {
    weeklyGoalKm = double.tryParse(value.replaceAll(',', '.'));
    notifyListeners();
  }

  void nextStep() {
    if (!canAdvance || isLastStep) return;
    _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep == 0) return;
    _currentStep--;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (!canAdvance || _isSaving) return false;

    _isSaving = true;
    hasError = false;
    notifyListeners();

    try {
      await _saveUserProfileUseCase(
        UserProfileEntity(
          name: name.trim(),
          age: age!,
          weeklyGoalKm: weeklyGoalKm!,
          weightKg: weightKg!,
          heightCm: heightCm!,
        ),
      );
      return true;
    } catch (e) {
      hasError = true;
      debugPrint('OnboardingController.submit error: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
