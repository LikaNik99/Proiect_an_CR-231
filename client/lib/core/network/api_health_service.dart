/// Small helper to short-circuit API calls when server is known down.
///
/// When we detect a connection-level failure, we mark API as down for a short
/// window, so subsequent requests can stop waiting and fallback to cache.
class ApiHealthService {
  static DateTime? _apiDownUntil;
  static int _failureStreak = 0;

  static bool get isApiDown {
    final until = _apiDownUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  static void markDown([Duration duration = const Duration(seconds: 8)]) {
    _failureStreak = (_failureStreak + 1).clamp(1, 6);
    final backoffMs = (duration.inMilliseconds * _failureStreak).clamp(2000, 20000);
    _apiDownUntil = DateTime.now().add(Duration(milliseconds: backoffMs));
  }

  static void markUp() {
    _apiDownUntil = null;
    _failureStreak = 0;
  }

  static void clear() => markUp();
}
