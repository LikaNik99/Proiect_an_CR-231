import 'package:hive/hive.dart';

/// Operation type for admin sync queue
enum AdminOperationType {
  create,
  update,
  delete,
}

/// Sync operation status
enum AdminSyncStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// Represents an operation to be synced when online
@HiveType(typeId: 20)
class AdminSyncOperation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final AdminOperationType type;

  @HiveField(2)
  final String entity;

  @HiveField(3)
  final Map<String, dynamic> data;

  @HiveField(4)
  int retryCount;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  AdminSyncStatus status;

  @HiveField(7)
  String? errorMessage;

  @HiveField(8)
  DateTime? lastAttempt;

  AdminSyncOperation({
    required this.id,
    required this.type,
    required this.entity,
    required this.data,
    this.retryCount = 0,
    required this.timestamp,
    this.status = AdminSyncStatus.pending,
    this.errorMessage,
    this.lastAttempt,
  });

  AdminSyncOperation copyWith({
    String? id,
    AdminOperationType? type,
    String? entity,
    Map<String, dynamic>? data,
    int? retryCount,
    DateTime? timestamp,
    AdminSyncStatus? status,
    String? errorMessage,
    DateTime? lastAttempt,
  }) {
    return AdminSyncOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      entity: entity ?? this.entity,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastAttempt: lastAttempt ?? this.lastAttempt,
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
      'errorMessage': errorMessage,
      'lastAttempt': lastAttempt?.toIso8601String(),
    };
  }

  factory AdminSyncOperation.fromJson(Map<String, dynamic> json) {
    return AdminSyncOperation(
      id: json['id'],
      type: AdminOperationType.values.firstWhere((e) => e.name == json['type']),
      entity: json['entity'],
      data: Map<String, dynamic>.from(json['data']),
      retryCount: json['retryCount'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      status: AdminSyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AdminSyncStatus.pending,
      ),
      errorMessage: json['errorMessage'],
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'])
          : null,
    );
  }

  @override
  String toString() {
    return 'AdminSyncOperation(id: $id, type: ${type.name}, entity: $entity, status: ${status.name})';
  }
}
