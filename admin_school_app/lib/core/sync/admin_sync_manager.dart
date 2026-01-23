import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'admin_sync_queue.dart';
import 'admin_sync_operation.dart';

/// Manages synchronization of admin operations with server
class AdminSyncManager {
  static final AdminSyncManager _instance = AdminSyncManager._internal();
  factory AdminSyncManager() => _instance;
  AdminSyncManager._internal();

  final AdminSyncQueue _queue = AdminSyncQueue();
  Dio? _dio;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  String serverUrl = 'http://10.240.0.129:8000';
  String? _authToken;

  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();

  /// Stream of pending operations count
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  /// Last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Is currently syncing
  bool get isSyncing => _isSyncing;

  /// Pending operations count
  int get pendingCount => _queue.pendingCount;

  /// Initialize sync manager
  Future<void> initialize({String? authToken}) async {
    _authToken = authToken;
    _dio = Dio(BaseOptions(
      baseUrl: serverUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    if (_authToken != null) {
      _dio!.options.headers['Authorization'] = 'Bearer $_authToken';
    }

    await _queue.initialize();
    debugPrint('AdminSyncManager initialized');
  }

  /// Set auth token
  void setAuthToken(String token) {
    _authToken = token;
    if (_dio != null) {
      _dio!.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Start periodic sync
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    stopPeriodicSync();
    _periodicSyncTimer = Timer.periodic(interval, (_) {
      if (!_isSyncing) {
        syncNow();
      }
    });
    debugPrint('Periodic sync started (every ${interval.inMinutes} min)');
  }

  /// Stop periodic sync
  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Sync now
  Future<bool> syncNow() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress');
      return false;
    }

    final pending = _queue.getPendingOperations();
    if (pending.isEmpty) {
      debugPrint('No pending operations to sync');
      return true;
    }

    _isSyncing = true;
    debugPrint('Starting sync of ${pending.length} operations...');

    int successCount = 0;
    int failCount = 0;

    for (var operation in pending) {
      try {
        await _queue.updateOperation(
          operation.copyWith(status: AdminSyncStatus.inProgress),
        );

        await _executeOperation(operation);

        await _queue.markCompleted(operation.id);
        successCount++;
        debugPrint('✓ Synced ${operation.entity} ${operation.type.name}');
      } catch (e) {
        await _queue.markFailed(operation.id, e.toString());
        failCount++;
        debugPrint('✗ Failed ${operation.entity}: $e');
      }
    }


    await _queue.clearCompleted();

    _lastSyncTime = DateTime.now();
    _isSyncing = false;

    _pendingCountController.add(_queue.pendingCount);

    debugPrint('Sync completed: $successCount success, $failCount failed');
    return failCount == 0;
  }

  /// Execute a single operation
  Future<void> _executeOperation(AdminSyncOperation operation) async {
    if (_dio == null) throw Exception('Dio not initialized');

    final endpoint = _getEndpointForEntity(operation.entity);

    switch (operation.type) {
      case AdminOperationType.create:
        await _dio!.post(endpoint, data: operation.data);
        break;

      case AdminOperationType.update:
        final id = operation.data['id'];
        await _dio!.put('$endpoint/$id', data: operation.data);
        break;

      case AdminOperationType.delete:
        final id = operation.data['id'];
        await _dio!.delete('$endpoint/$id');
        break;
    }
  }

  /// Get endpoint for entity
  String _getEndpointForEntity(String entity) {
    final endpoints = {
      'school': '/api/schools',
      'teacher': '/api/teachers',
      'student': '/api/students',
      'class': '/api/classes',
      'subject': '/api/subjects',
      'grade': '/api/grades',
      'homework': '/api/homework',
      'attendance': '/api/attendance',
    };

    return endpoints[entity] ?? '/api/$entity';
  }

  /// Add operation to queue
  Future<String> queueOperation({
    required AdminOperationType type,
    required String entity,
    required Map<String, dynamic> data,
  }) async {
    final operation = AdminSyncOperation(
      id: '',
      type: type,
      entity: entity,
      data: data,
      timestamp: DateTime.now(),
    );

    final id = await _queue.enqueue(operation);
    _pendingCountController.add(_queue.pendingCount);

    debugPrint('Queued ${type.name} for $entity (ID: $id)');


    if (!_isSyncing) {
      syncNow();
    }

    return id;
  }

  /// Get queue stats
  Map<String, int> getQueueStats() {
    final all = _queue.getAllOperations();
    final pending = _queue.getPendingOperations();

    return {
      'total': all.length,
      'pending': pending.length,
      'completed': all.where((op) => op.status == AdminSyncStatus.completed).length,
      'failed': all.where((op) => op.status == AdminSyncStatus.failed).length,
    };
  }

  /// Dispose
  void dispose() {
    stopPeriodicSync();
    _pendingCountController.close();
  }
}
