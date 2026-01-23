import '../../domain/entities/attendance_entity.dart';

class AttendanceModel extends Attendance {
  const AttendanceModel({
    required super.id,
    required super.attendanceDate,
    required super.status,
    super.notes,
    required super.studentId,
    required super.subjectId,
    super.subjectName,
    required super.teacherId,
    required super.createdAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      attendanceDate: DateTime.parse(json['attendance_date']),
      status: _statusFromString(json['status']),
      notes: json['notes'],
      studentId: json['student_id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject']?['name'],
      teacherId: json['teacher_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'status': _statusToString(status),
      'notes': notes,
      'student_id': studentId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
    };
  }

  static AttendanceStatus _statusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.present;
    }
  }

  static String _statusToString(AttendanceStatus status) {
    return status.name;
  }
}
