import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum ConnectionMode {
  auto,
  directDb,
}

class ConnectionModeService {
  static final _storage = FlutterSecureStorage();
  static const _modeKey = 'admin_connection_mode';

  static Future<void> save(ConnectionMode mode) async {
    await _storage.write(key: _modeKey, value: mode.name);
  }

  static Future<ConnectionMode> load() async {
    final v = await _storage.read(key: _modeKey);
    if (v == ConnectionMode.directDb.name) return ConnectionMode.directDb;
    return ConnectionMode.auto;
  }
}
