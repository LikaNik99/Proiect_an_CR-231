import '../../domain/entities/homework_entity.dart';

class HomeworkModel extends Homework {
  const HomeworkModel({
    required super.id,
    required super.title,
    super.description,
    required super.dueDate,
    required super.status,
    required super.subjectId,
    super.subjectName,
    required super.classId,
    required super.teacherId,
    required super.createdAt,
    super.assignedStudentIds,
    super.isPersonal,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    final assignedIds = (json['assigned_student_ids'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    return HomeworkModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      status: _statusFromString(json['status']),
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject']?['name'],
      classId: json['class_id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      assignedStudentIds: assignedIds,
      isPersonal: json['is_personal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'subject_id': subjectId,
      'class_id': classId,
      'teacher_id': teacherId,
    };
  }

  static HomeworkStatus _statusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return HomeworkStatus.completed;
      case 'overdue':
        return HomeworkStatus.overdue;
      default:
        return HomeworkStatus.pending;
    }
  }
}
