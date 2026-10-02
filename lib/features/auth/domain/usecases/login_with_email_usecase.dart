import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithEmailUseCase {
  final AuthRepository repository;

  LoginWithEmailUseCase(this.repository);

  Future<UserEntity> call(String email, String password) {
    return repository.loginWithEmail(email, password);
  }
}
