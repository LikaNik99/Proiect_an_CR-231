import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class CheckEmailUseCase {
  final AuthRepository repository;

  CheckEmailUseCase(this.repository);

  Future<UserEntity?> call(String email) async {
    return await repository.checkEmail(email);
  }
}
