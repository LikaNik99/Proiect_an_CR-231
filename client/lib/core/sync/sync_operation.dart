enum OperationType { create, update, delete }

enum SyncStatus { pending, processing, done, failed }

class SyncOperation {
  final String id;
  final OperationType type;
  final String entity;
  final Map<String, dynamic> data;
  final int retryCount;
  final DateTime timestamp;
  final SyncStatus status;

  const SyncOperation({
    required this.id,
    required this.type,
    required this.entity,
    required this.data,
    required this.retryCount,
    required this.timestamp,
    required this.status,
  });

  SyncOperation copyWith({
    int? retryCount,
    SyncStatus? status,
  }) {
    return SyncOperation(
      id: id,
      type: type,
      entity: entity,
      data: data,
      retryCount: retryCount ?? this.retryCount,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'entity': entity,
      'data': data,
      'retryCount': retryCount,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }

  static SyncOperation fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: (json['id'] ?? '').toString(),
      type: OperationType.values.firstWhere((e) => e.name == json['type'], orElse: () => OperationType.update),
      entity: (json['entity'] ?? '').toString(),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      retryCount: (json['retryCount'] as int?) ?? 0,
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ?? DateTime.now(),
      status: SyncStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => SyncStatus.pending),
    );
  }
}
