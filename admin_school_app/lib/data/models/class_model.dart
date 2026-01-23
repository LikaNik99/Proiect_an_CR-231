import '../../domain/entities/class_entity.dart';

class ClassModel extends ClassEntity {
  ClassModel({
    super.id,
    required super.name,
    super.teacherId,
    required super.schoolId,
    super.createdAt,
    super.updatedAt,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString(),
      name: (json['name'] ?? '').toString(),
      teacherId: json['teacher_id']?.toString(),
      schoolId: json['school_id'].toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (teacherId != null && teacherId!.isNotEmpty) 'teacher_id': teacherId,
      'school_id': schoolId,
    };
  }
}