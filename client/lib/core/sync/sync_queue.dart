import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'sync_operation.dart';

class SyncQueue {
  static const _boxName = 'sync_queue_box';
  final _uuid = const Uuid();

  Future<void> init() async {

    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<dynamic>(_boxName);
    }
  }

  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  Future<int> pendingCount() async {
    return _box.values.length;
  }

  Future<void> enqueue({
    required OperationType type,
    required String entity,
    required Map<String, dynamic> data,
  }) async {
    final op = SyncOperation(
      id: _uuid.v4(),
      type: type,
      entity: entity,
      data: data,
      retryCount: 0,
      timestamp: DateTime.now(),
      status: SyncStatus.pending,
    );
    await _box.put(op.id, op.toJson());
  }

  Future<List<SyncOperation>> peekAll() async {
    return _box.values
        .map((e) => SyncOperation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  Future<void> update(SyncOperation op) async {
    await _box.put(op.id, op.toJson());
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
