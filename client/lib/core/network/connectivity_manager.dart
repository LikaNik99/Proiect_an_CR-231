import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_health_service.dart';
import 'connection_status.dart';

enum ConnectivityStatus {
  online,
  offline,
  serverDown,
}

class ConnectivityManager {
  final Connectivity _connectivity;
  final Dio _dio;

  final _controller = StreamController<ConnectionStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _poll;

  ConnectionStatus _current = ConnectionStatus(
    state: ConnectionStateType.offline,
    checkedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Rich status for UI.
  ConnectionStatus get currentStatus => _current;
  Stream<ConnectionStatus> get stream => _controller.stream;

  /// Backwards compatible simple status.
  ConnectivityStatus get current {
    return switch (_current.state) {
      ConnectionStateType.online => ConnectivityStatus.online,
      ConnectionStateType.offline => ConnectivityStatus.offline,
      ConnectionStateType.serverDown => ConnectivityStatus.serverDown,
    };
  }

  ConnectivityManager({Connectivity? connectivity, required Dio dio})
      : _connectivity = connectivity ?? Connectivity(),
        _dio = dio;

  Future<void> start({Duration pollInterval = const Duration(seconds: 10)}) async {
    await _recomputeAndEmit();

    _sub?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen((_) async {
      await _recomputeAndEmit();
    });


    _poll?.cancel();
    _poll = Timer.periodic(pollInterval, (_) {
      unawaited(_recomputeAndEmit());
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _poll?.cancel();
    await _controller.close();
  }

  Future<bool> hasNetwork() async {
    final res = await _connectivity.checkConnectivity();
    return !res.contains(ConnectivityResult.none);
  }

  Future<bool> isServerReachable() async {
    if (ApiHealthService.isApiDown) return false;

    const candidates = <String>[
      '/',
    ];

    for (final path in candidates) {
      final ok = await _probe(path);
      if (ok) return true;
    }

    return false;
  }

  Future<bool> _probe(String path) async {
    try {
      final opts = Options(
        followRedirects: false,
        sendTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
        validateStatus: (code) {
          if (code == null) return false;
          return (code >= 200 && code < 300) || (code >= 300 && code < 400);
        },
      );

      try {
        final r = await _dio.head(path, options: opts);
        return (r.statusCode != null) && opts.validateStatus!(r.statusCode!);
      } catch (_) {
        final r = await _dio.get(path, options: opts);
        return (r.statusCode != null) && opts.validateStatus!(r.statusCode!);
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _recomputeAndEmit() async {
    final checkedAt = DateTime.now();

    final network = await hasNetwork();
    if (!network) {
      _setAndEmit(
        ConnectionStatus(
          state: ConnectionStateType.offline,
          checkedAt: checkedAt,
          details: 'Nu există conexiune la internet',
        ),
      );
      return;
    }

    if (ApiHealthService.isApiDown) {
      _setAndEmit(
        ConnectionStatus(
          state: ConnectionStateType.serverDown,
          checkedAt: checkedAt,
          details: 'Server indisponibil (detectat recent) – folosim cache',
        ),
      );
      return;
    }

    final ok = await isServerReachable();
    _setAndEmit(
      ConnectionStatus(
        state: ok ? ConnectionStateType.online : ConnectionStateType.serverDown,
        checkedAt: checkedAt,
        details: ok ? 'Conectat la server' : 'Server indisponibil – folosim cache',
      ),
    );
  }

  void _setAndEmit(ConnectionStatus s) {
    if (_current.state == s.state) {

      _current = s;
      return;
    }
    _current = s;
    _controller.add(s);
  }
}
