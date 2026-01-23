import '../../domain/entities/admin_user_entity.dart';

class AdminUserModel extends AdminUserEntity {
  AdminUserModel({
    super.id,
    required super.username,
    required super.email,
    required super.role,
    super.isActivated = false,
    super.schoolId,
    super.createdAt,
    super.updatedAt,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id']?.toString(),
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActivated: json['is_activated'] as bool? ?? false,
      schoolId: json['school_id']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'email': email,
      'role': role,
      'is_activated': isActivated,
      if (schoolId != null) 'school_id': schoolId,
    };
  }
}