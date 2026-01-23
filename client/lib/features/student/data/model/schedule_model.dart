class ScheduleModel {
  final String id;
  final String dayOfWeek;
  final int periodNumber;
  final String startTime;
  final String endTime;
  final String? room;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String classId;

  ScheduleModel({
    required this.id,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.classId,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 'monday',
      periodNumber: json['period_number'] ?? 1,
      startTime: json['start_time'] ?? '08:00',
      endTime: json['end_time'] ?? '09:00',
      room: json['room'],
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject']?['name'] ?? 'Unknown',
      teacherId: json['teacher_id'] ?? '',
      classId: json['class_id'] ?? '',
    );
  }
}