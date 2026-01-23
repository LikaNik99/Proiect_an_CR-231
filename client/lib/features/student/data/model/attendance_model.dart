class AttendanceModel {
  final String id;
  final DateTime attendanceDate;
  final String status;
  final String? notes;
  final String subjectId;
  final String subjectName;
  final String teacherId;

  AttendanceModel({
    required this.id,
    required this.attendanceDate,
    required this.status,
    this.notes,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      attendanceDate: DateTime.parse(json['attendance_date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'present',
      notes: json['notes'],
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject']?['name'] ?? 'Unknown',
      teacherId: json['teacher_id'] ?? '',
    );
  }
}