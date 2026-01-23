import 'dart:async';
import 'package:postgres/postgres.dart';
import '../services/admin_db_config_service.dart';

/// Minimal PostgreSQL connection manager used for direct DB fallback.
///
/// NOTE: credentials should come from secure storage / settings UI.
class DatabaseConnectionManager {
  static final DatabaseConnectionManager _instance = DatabaseConnectionManager._internal();
  factory DatabaseConnectionManager() => _instance;
  DatabaseConnectionManager._internal();

  Connection? _conn;


  String host = 'localhost';
  int port = 5432;
  String database = 'school_db';
  String username = 'postgres';
  String password = 'postgres';
  bool useSSL = false;

  void configure({
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
    bool? useSSL,
  }) {
    if (host != null) this.host = host;
    if (port != null) this.port = port;
    if (database != null) this.database = database;
    if (username != null) this.username = username;
    if (password != null) this.password = password;
    if (useSSL != null) this.useSSL = useSSL;
  }

  bool get isConnected => _conn != null;

  Future<bool> connectToPostgres({
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
    bool? useSSL,
  }) async {

    if (host == null && database == null && username == null && password == null) {
      final cfg = await AdminDbConfigService.load();
      if (cfg != null) {
        configure(
          host: cfg.host,
          port: cfg.port,
          database: cfg.database,
          username: cfg.username,
          password: cfg.password,
          useSSL: cfg.useSSL,
        );
      }
    }

    configure(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
      useSSL: useSSL,
    );

    if (_conn != null) return true;

    final endpoint = Endpoint(
      host: this.host,
      port: this.port,
      database: this.database,
      username: this.username,
      password: this.password,
    );

    _conn = await Connection.open(
      endpoint,
      settings: ConnectionSettings(
        sslMode: this.useSSL ? SslMode.require : SslMode.disable,
        connectTimeout: const Duration(seconds: 10),
        queryTimeout: const Duration(seconds: 20),
      ),
    );


    await _conn!.execute('SELECT 1');
    return true;
  }

  Future<void> disconnect() async {
    await _conn?.close();
    _conn = null;
  }

  Future<void> ensureConnected() async {
    if (_conn != null) return;
    await connectToPostgres();
  }

  /// Executes a SELECT and returns List<Map<column,value>>.
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    await ensureConnected();

    final result = await _conn!.execute(
      Sql.named(sql),
      parameters: _params(params),
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  /// Executes INSERT/UPDATE/DELETE and returns affected rows.
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    await ensureConnected();

    final result = await _conn!.execute(
      Sql.named(sql),
      parameters: _params(params),
    );

    return result.affectedRows;
  }

  Map<String, dynamic>? _params(List<dynamic>? params) {
    if (params == null || params.isEmpty) return null;
    return Map.fromIterables(
      List.generate(params.length, (i) => i.toString()),
      params,
    );
  }
}
