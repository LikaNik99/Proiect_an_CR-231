import 'package:equatable/equatable.dart';

enum GradeType { exam, test, homework, assignment, other }

class Grade extends Equatable {
  final String id;
  final int value;
  final GradeType type;
  final String studentId;
  final String teacherId;
  final String subjectId;
  final String? subjectName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Grade({
    required this.id,
    required this.value,
    required this.type,
    required this.studentId,
    required this.teacherId,
    required this.subjectId,
    this.subjectName,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        value,
        type,
        studentId,
        teacherId,
        subjectId,
        subjectName,
        createdAt,
        updatedAt,
      ];
}
