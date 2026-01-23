import '../../entities/admin_user_entity.dart';
import '../../repositories/admin_user_repository.dart';

class UpdateUserUseCase {
  final AdminUserRepository repository;

  UpdateUserUseCase(this.repository);

  Future<AdminUserEntity?> call(String userId, AdminUserEntity user) async {
    return await repository.updateUser(userId, user);
  }
}