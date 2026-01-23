import 'dart:async';

/// Small helper to short-circuit API calls when server is known down.
///
/// When we detect a connection-level failure, we mark API as down for a short
/// window so subsequent requests can skip waiting and fallback to DB immediately.
class ApiHealthService {
  static DateTime? _apiDownUntil;

  static bool get isApiDown {
    final until = _apiDownUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  /// Mark API down for [duration].
  static void markDown([Duration duration = const Duration(seconds: 8)]) {
    _apiDownUntil = DateTime.now().add(duration);
  }

  static void markUp() {
    _apiDownUntil = null;
  }

  static Future<T> guard<T>(Future<T> Function() call) async {
    if (isApiDown) {
      throw TimeoutException('API_DOWN');
    }
    return await call();
  }
}
