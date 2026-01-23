import '../../entities/admin_user_entity.dart';
import '../../repositories/admin_user_repository.dart';

class CreateUserUseCase {
  final AdminUserRepository repository;

  CreateUserUseCase(this.repository);

  Future<AdminUserEntity?> call(AdminUserEntity user) async {
    return await repository.createUser(user);
  }
}