import '../../entities/admin_user_entity.dart';
import '../../repositories/admin_user_repository.dart';

class GetUserUseCase {
  final AdminUserRepository repository;

  GetUserUseCase(this.repository);

  Future<AdminUserEntity?> call(String userId) async {
    return await repository.getUser(userId);
  }
}