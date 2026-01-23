import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'admin_sync_operation.dart';

/// Manages queue of operations to sync when server becomes available
class AdminSyncQueue {
  static final AdminSyncQueue _instance = AdminSyncQueue._internal();
  factory AdminSyncQueue() => _instance;
  AdminSyncQueue._internal();

  static const String _boxName = 'admin_sync_queue';
  Box<Map>? _box;
  final Uuid _uuid = const Uuid();

  /// Initialize the sync queue
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Map>(_boxName);
    } else {
      _box = Hive.box<Map>(_boxName);
    }
  }

  /// Add operation to queue
  Future<String> enqueue(AdminSyncOperation operation) async {
    if (_box == null) await initialize();

    final id = operation.id.isEmpty ? _uuid.v4() : operation.id;
    final op = operation.copyWith(id: id);

    await _box!.put(id, op.toJson());
    return id;
  }

  /// Get all pending operations
  List<AdminSyncOperation> getPendingOperations() {
    if (_box == null) return [];

    final operations = <AdminSyncOperation>[];
    for (var entry in _box!.values) {
      final op = AdminSyncOperation.fromJson(Map<String, dynamic>.from(entry));
      if (op.status == AdminSyncStatus.pending || op.status == AdminSyncStatus.failed) {
        operations.add(op);
      }
    }


    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  /// Get all operations
  List<AdminSyncOperation> getAllOperations() {
    if (_box == null) return [];

    final operations = <AdminSyncOperation>[];
    for (var entry in _box!.values) {
      operations.add(AdminSyncOperation.fromJson(Map<String, dynamic>.from(entry)));
    }

    operations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return operations;
  }

  /// Update operation
  Future<void> updateOperation(AdminSyncOperation operation) async {
    if (_box == null) await initialize();
    await _box!.put(operation.id, operation.toJson());
  }

  /// Mark operation as completed
  Future<void> markCompleted(String id) async {
    if (_box == null) await initialize();

    final data = _box!.get(id);
    if (data != null) {
      final op = AdminSyncOperation.fromJson(Map<String, dynamic>.from(data));
      await _box!.put(
        id,
        op.copyWith(status: AdminSyncStatus.completed).toJson(),
      );
    }
  }

  /// Mark operation as failed
  Future<void> markFailed(String id, String errorMessage) async {
    if (_box == null) await initialize();

    final data = _box!.get(id);
    if (data != null) {
      final op = AdminSyncOperation.fromJson(Map<String, dynamic>.from(data));
      await _box!.put(
        id,
        op.copyWith(
          status: AdminSyncStatus.failed,
          errorMessage: errorMessage,
          retryCount: op.retryCount + 1,
          lastAttempt: DateTime.now(),
        ).toJson(),
      );
    }
  }

  /// Remove operation
  Future<void> remove(String id) async {
    if (_box == null) await initialize();
    await _box!.delete(id);
  }

  /// Clear completed operations
  Future<void> clearCompleted() async {
    if (_box == null) await initialize();

    final toDelete = <String>[];
    for (var key in _box!.keys) {
      final data = _box!.get(key);
      if (data != null) {
        final op = AdminSyncOperation.fromJson(Map<String, dynamic>.from(data));
        if (op.status == AdminSyncStatus.completed) {
          toDelete.add(key.toString());
        }
      }
    }

    for (var key in toDelete) {
      await _box!.delete(key);
    }
  }

  /// Get pending count
  int get pendingCount {
    return getPendingOperations().length;
  }

  /// Check if has pending operations
  bool get hasPendingOperations {
    return pendingCount > 0;
  }

  /// Clear all
  Future<void> clearAll() async {
    if (_box == null) await initialize();
    await _box!.clear();
  }
}
