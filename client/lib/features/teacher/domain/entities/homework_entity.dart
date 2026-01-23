import 'package:equatable/equatable.dart';

enum HomeworkStatus {
  pending,
  completed,
  overdue,
}

class Homework extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final HomeworkStatus status;
  final String subjectId;
  final String? subjectName;
  final String classId;
  final String teacherId;
  final DateTime createdAt;
  final List<String> assignedStudentIds;
  final bool isPersonal;

  const Homework({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.status,
    required this.subjectId,
    this.subjectName,
    required this.classId,
    required this.teacherId,
    required this.createdAt,
    this.assignedStudentIds = const [],
    this.isPersonal = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        dueDate,
        status,
        subjectId,
        subjectName,
        classId,
        teacherId,
        createdAt,
        assignedStudentIds,
        isPersonal,
      ];
}
