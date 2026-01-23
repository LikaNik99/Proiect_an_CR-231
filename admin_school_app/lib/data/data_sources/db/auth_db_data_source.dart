import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../../core/database/database_connection_manager.dart';
import '../../models/user_model.dart';

/// Direct DB auth for Admin app.
///
/// This allows login when API/server is down, by validating credentials against
/// the Postgres users table.
class AuthDbDataSource {
  final DatabaseConnectionManager db;

  AuthDbDataSource(this.db);

  /// Attempts to login by (email, password) directly from the DB.
  ///
  /// Assumptions:
  /// - users table has columns: id, email, username, role, is_activated, password
  /// - password stored as plain text OR sha256(password) (dev). We support both.
  Future<UserModel?> login(String email, String password) async {
    final rows = await db.query('''
      SELECT id, username, email, role, is_activated, password
      FROM users
      WHERE email = @0
      LIMIT 1
    ''', [email]);

    if (rows.isEmpty) return null;

    final r = rows.first;
    final stored = (r['password'] ?? '').toString();

    final sha = sha256.convert(utf8.encode(password)).toString();
    final ok = stored == password || stored == sha;
    if (!ok) return null;

    final userId = (r['id'] ?? '').toString();
    return UserModel(
      username: (r['username'] ?? '').toString(),
      email: (r['email'] ?? '').toString(),
      role: (r['role'] ?? '').toString(),
      isActive: (r['is_activated'] == true) || (r['is_activated']?.toString() == 'true'),
      userId: userId,
      exists: true,

      accessToken: 'local-db',
      refreshToken: 'local-db',
    );
  }
}
