import '../entities/admin_user_entity.dart';

abstract class AdminUserRepository {
  Future<List<AdminUserEntity>> getUsers();
  Future<AdminUserEntity?> getUser(String userId);
  Future<AdminUserEntity?> createUser(AdminUserEntity user);
  Future<AdminUserEntity?> updateUser(String userId, AdminUserEntity user);
  Future<bool> deleteUser(String userId);
}