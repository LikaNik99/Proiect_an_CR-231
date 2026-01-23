import 'package:dio/dio.dart';
import '../models/admin_user_model.dart';
import '../../core/database/database_connection_manager.dart';
import '../../core/database/db_error_mapper.dart';
import '../../core/network/network_fallback.dart';
import 'db/admin_user_db_data_source.dart';

class AdminUserDataSource {
  final Dio dio;
  final AdminUserDbDataSource dbDataSource;

  AdminUserDataSource(this.dio, DatabaseConnectionManager dbManager)
      : dbDataSource = AdminUserDbDataSource(dbManager);

  Future<List<AdminUserModel>> getUsers() async {
    try {
      final response = await dio.get('/users/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => AdminUserModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      final errObj = e is Object ? e : Exception('Unknown error');
      if (NetworkFallback.shouldFallback(errObj)) {
        try {
          return await dbDataSource.getUsers();
        } catch (dbErr) {
          throw Exception(DbErrorMapper.toUserMessage(dbErr is Object ? dbErr : Exception('Unknown DB error')));
        }
      }
      throw Exception(NetworkFallback.describe(errObj));
    }
  }

  Future<AdminUserModel?> getUser(String userId) async {
    try {
      final response = await dio.get('/users/$userId');
      return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        final all = await dbDataSource.getUsers();
        try {
          return all.firstWhere((u) => u.id == userId);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  Future<AdminUserModel?> createUser(AdminUserModel user) async {

    try {
      final response = await dio.post('/users/', data: user.toJson());
      return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        throw Exception('Direct DB create user is not supported (password hashing required).');
      }
      return null;
    }
  }

  Future<AdminUserModel?> updateUser(String userId, AdminUserModel user) async {
    try {
      final response = await dio.put('/users/$userId', data: user.toJson());
      return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        throw Exception('Direct DB update user is not supported for now.');
      }
      return null;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await dio.delete('/users/$userId');
      return true;
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.deleteUser(userId);
      }
      return false;
    }
  }
}
