import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores Postgres connection settings for direct DB mode.
///
/// Values are stored locally on the admin machine (Windows) using secure storage.
class AdminDbConfigService {
  static final _storage = FlutterSecureStorage();

  static const _hostKey = 'admin_db_host';
  static const _portKey = 'admin_db_port';
  static const _dbKey = 'admin_db_name';
  static const _userKey = 'admin_db_user';
  static const _passKey = 'admin_db_pass';
  static const _sslKey = 'admin_db_ssl';

  static Future<void> save({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
    bool useSSL = false,
  }) async {
    await _storage.write(key: _hostKey, value: host);
    await _storage.write(key: _portKey, value: port.toString());
    await _storage.write(key: _dbKey, value: database);
    await _storage.write(key: _userKey, value: username);
    await _storage.write(key: _passKey, value: password);
    await _storage.write(key: _sslKey, value: useSSL ? 'true' : 'false');
  }

  static Future<AdminDbConfig?> load() async {
    final host = await _storage.read(key: _hostKey);
    final portStr = await _storage.read(key: _portKey);
    final database = await _storage.read(key: _dbKey);
    final username = await _storage.read(key: _userKey);
    final password = await _storage.read(key: _passKey);
    final sslStr = await _storage.read(key: _sslKey);

    if (host == null || database == null || username == null || password == null) {
      return null;
    }

    return AdminDbConfig(
      host: host,
      port: int.tryParse(portStr ?? '') ?? 5432,
      database: database,
      username: username,
      password: password,
      useSSL: sslStr == 'true',
    );
  }
}

class AdminDbConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool useSSL;

  const AdminDbConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    required this.useSSL,
  });
}
