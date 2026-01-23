import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> checkEmail(String email);

  Future<UserEntity?> login(String email, String password);
}
