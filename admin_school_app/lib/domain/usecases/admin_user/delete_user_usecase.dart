import '../../repositories/admin_user_repository.dart';

class DeleteUserUseCase {
  final AdminUserRepository repository;

  DeleteUserUseCase(this.repository);

  Future<bool> call(String userId) async {
    return await repository.deleteUser(userId);
  }
}