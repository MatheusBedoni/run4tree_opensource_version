import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> loginWithEmail(String email, String password);
  Future<UserEntity> loginWithGoogle();
}
