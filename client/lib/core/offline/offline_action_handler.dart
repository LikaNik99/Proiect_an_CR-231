import 'package:dio/dio.dart';

import '../network/connection_status.dart';
import '../network/connectivity_manager.dart';
import '../sync/sync_operation.dart';
import '../sync/sync_queue.dart';

/// Helper that makes a write-operation offline-first:
/// - tries remote
/// - if remote fails due to connectivity/server down -> enqueue
///
/// It does NOT implement offline login.
class OfflineActionHandler {
  final ConnectivityManager connectivity;
  final SyncQueue queue;

  OfflineActionHandler({required this.connectivity, required this.queue});

  bool _shouldQueue(Object e) {
    if (connectivity.currentStatus.state != ConnectionStateType.online) return true;
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.unknown ||
          e.response == null;
    }
    return false;
  }

  Future<T?> run<T>({
    required OperationType opType,
    required String entity,
    required Map<String, dynamic> payload,
    required Future<T> Function() remoteCall,
  }) async {
    try {
      return await remoteCall();
    } catch (e) {
      if (_shouldQueue(e is Object ? e : Exception('Unknown error'))) {
        await queue.enqueue(type: opType, entity: entity, data: payload);
        return null;
      }
      rethrow;
    }
  }
}
