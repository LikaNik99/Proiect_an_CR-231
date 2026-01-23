import '../../domain/entities/admin_user_entity.dart';
import '../../domain/repositories/admin_user_repository.dart';
import '../data_sources/admin_user_data_source.dart';
import '../models/admin_user_model.dart';

class AdminUserRepositoryImpl implements AdminUserRepository {
  final AdminUserDataSource dataSource;

  AdminUserRepositoryImpl(this.dataSource);

  @override
  Future<List<AdminUserEntity>> getUsers() async {
    return await dataSource.getUsers();
  }

  @override
  Future<AdminUserEntity?> getUser(String userId) async {
    return await dataSource.getUser(userId);
  }

  @override
  Future<AdminUserEntity?> createUser(AdminUserEntity user) async {
    final model = AdminUserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      isActivated: user.isActivated,
      schoolId: user.schoolId,
    );
    return await dataSource.createUser(model);
  }

  @override
  Future<AdminUserEntity?> updateUser(String userId, AdminUserEntity user) async {
    final model = AdminUserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      isActivated: user.isActivated,
      schoolId: user.schoolId,
    );
    return await dataSource.updateUser(userId, model);
  }

  @override
  Future<bool> deleteUser(String userId) async {
    return await dataSource.deleteUser(userId);
  }
}