import '../../entities/admin_user_entity.dart';
import '../../repositories/admin_user_repository.dart';

class GetUsersUseCase {
  final AdminUserRepository repository;

  GetUsersUseCase(this.repository);

  Future<List<AdminUserEntity>> call() async {
    return await repository.getUsers();
  }
}