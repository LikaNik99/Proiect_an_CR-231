import '../../models/admin_user_model.dart';
import '../../../core/database/database_connection_manager.dart';
import '../../../core/database/soft_delete_support.dart';

/// Direct DB datasource for admin users (PostgreSQL)
class AdminUserDbDataSource {
  final DatabaseConnectionManager db;

  AdminUserDbDataSource(this.db);

  Future<List<AdminUserModel>> getUsers() async {
    try {
      final rows = await db.query('''
        SELECT id, username, email, role, is_activated, school_id, created_at, updated_at
        FROM users
        WHERE deleted_at IS NULL
        ORDER BY created_at DESC
      ''');
      return rows.map((r) => AdminUserModel.fromJson(r)).toList();
    } catch (e) {
      if (SoftDeleteSupport.isMissingDeletedAtColumn(e is Object ? e : Exception('Unknown error'))) {
        final rows = await db.query('''
          SELECT id, username, email, role, is_activated, school_id, created_at, updated_at
          FROM users
          ORDER BY created_at DESC
        ''');
        return rows.map((r) => AdminUserModel.fromJson(r)).toList();
      }
      rethrow;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final affected = await db.execute('''
        UPDATE users
        SET deleted_at = NOW(), updated_at = NOW()
        WHERE id = @0 AND deleted_at IS NULL
      ''', [userId]);
      return affected > 0;
    } catch (e) {
      if (SoftDeleteSupport.isMissingDeletedAtColumn(e is Object ? e : Exception('Unknown error'))) {

        final affected = await db.execute('DELETE FROM users WHERE id = @0', [userId]);
        return affected > 0;
      }
      rethrow;
    }
  }
}
