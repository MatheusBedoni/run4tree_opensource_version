import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<UserEntity> loginWithEmail(String email, String password) async {
    // TODO: Implement actual remote data source call
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(id: '1', email: email, name: 'Runner');
  }

  @override
  Future<UserEntity> loginWithGoogle() async {
    // TODO: Implement actual google sign in
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: '2',
      email: 'google@runner.com',
      name: 'Google Runner',
    );
  }
}
