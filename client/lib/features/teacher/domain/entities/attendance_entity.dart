import 'package:equatable/equatable.dart';

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

class Attendance extends Equatable {
  final String id;
  final DateTime attendanceDate;
  final AttendanceStatus status;
  final String? notes;
  final String studentId;
  final String subjectId;
  final String? subjectName;
  final String teacherId;
  final DateTime createdAt;

  const Attendance({
    required this.id,
    required this.attendanceDate,
    required this.status,
    this.notes,
    required this.studentId,
    required this.subjectId,
    this.subjectName,
    required this.teacherId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        attendanceDate,
        status,
        notes,
        studentId,
        subjectId,
        subjectName,
        teacherId,
        createdAt,
      ];
}
