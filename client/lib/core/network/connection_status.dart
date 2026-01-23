enum ConnectionStateType {
  /// No network (wifi/mobile off)
  offline,

  /// Network OK but API not reachable
  serverDown,

  /// API reachable
  online,
}

class ConnectionStatus {
  final ConnectionStateType state;
  final DateTime checkedAt;
  final String? details;

  const ConnectionStatus({
    required this.state,
    required this.checkedAt,
    this.details,
  });

  bool get isOnline => state == ConnectionStateType.online;
  bool get isOffline => state == ConnectionStateType.offline;
  bool get isServerDown => state == ConnectionStateType.serverDown;
}
