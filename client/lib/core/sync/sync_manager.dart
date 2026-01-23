import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/connectivity_manager.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

class SyncManager {
  final SyncQueue queue;
  final ConnectivityManager connectivity;
  final Dio dio;

  Timer? _timer;
  final _syncing = ValueNotifier<bool>(false);
  ValueListenable<bool> get syncing => _syncing;

  SyncManager({
    required this.queue,
    required this.connectivity,
    required this.dio,
  });

  Future<void> start({Duration interval = const Duration(seconds: 20)}) async {
    await queue.init();
    await connectivity.start();

    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      unawaited(syncNow());
    });


    connectivity.stream.listen((status) {
      if (status.isOnline) {
        unawaited(syncNow());
      }
    });
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> syncNow() async {
    if (_syncing.value) return;
    if (!connectivity.currentStatus.isOnline) return;

    _syncing.value = true;
    try {
      final ops = await queue.peekAll();
      for (final op in ops) {
        await _process(op);
      }
    } catch (e) {
      debugPrint('SyncManager syncNow failed: $e');
    } finally {
      _syncing.value = false;
    }
  }

  Future<void> _process(SyncOperation op) async {
    final processing = op.copyWith(status: SyncStatus.processing);
    await queue.update(processing);

    try {
      await _sendToServer(op);
      await queue.remove(op.id);
    } catch (e) {
      final failed = op.copyWith(
        status: SyncStatus.failed,
        retryCount: op.retryCount + 1,
      );
      await queue.update(failed);
    }
  }

  Future<void> _sendToServer(SyncOperation op) async {

    final entity = op.entity;
    switch (entity) {
      case 'attendance':

        await _sendGeneric('/attendance/', op);
        return;
      case 'homework':
        await _sendGeneric('/homework/', op);
        return;
      case 'grade':
        await _sendGeneric('/grades/', op);
        return;
      default:

        throw Exception('Unknown entity: $entity');
    }
  }

  Future<void> _sendGeneric(String basePath, SyncOperation op) async {
    switch (op.type) {
      case OperationType.create:
        await dio.post(basePath, data: op.data);
        return;
      case OperationType.update:
        final id = (op.data['id'] ?? '').toString();
        if (id.isEmpty) throw Exception('Missing id for update');
        await dio.put('$basePath$id', data: op.data);
        return;
      case OperationType.delete:
        final id = (op.data['id'] ?? '').toString();
        if (id.isEmpty) throw Exception('Missing id for delete');
        await dio.delete('$basePath$id');
        return;
    }
  }
}
