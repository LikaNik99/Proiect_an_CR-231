import '../../domain/entities/grade_entity.dart';

class GradeModel extends Grade {
  const GradeModel({
    required super.id,
    required super.value,
    required super.type,
    required super.studentId,
    required super.teacherId,
    required super.subjectId,
    super.subjectName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'] ?? '',
      value: json['value'] ?? 0,
      type: _gradeTypeFromString(json['types']),
      studentId: json['student_id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject']?['name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'types': _gradeTypeToString(type),
      'student_id': studentId,
      'teacher_id': teacherId,
      'subject_id': subjectId,
    };
  }

  static GradeType _gradeTypeFromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'exam':
        return GradeType.exam;
      case 'test':
        return GradeType.test;
      case 'homework':
        return GradeType.homework;
      case 'assignment':
        return GradeType.assignment;
      default:
        return GradeType.other;
    }
  }

  static String _gradeTypeToString(GradeType type) {
    return type.name;
  }
}
