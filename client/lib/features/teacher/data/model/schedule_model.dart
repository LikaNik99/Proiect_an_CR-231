import '../../domain/entities/schedule_entity.dart';

class ScheduleModel extends Schedule {
  const ScheduleModel({
    required super.id,
    required super.dayOfWeek,
    required super.periodNumber,
    required super.startTime,
    required super.endTime,
    super.room,
    required super.classId,
    super.className,
    required super.subjectId,
    super.subjectName,
    required super.teacherId,
    required super.createdAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final subjectId = (json['subject_id'] ?? json['subject']?['id'] ?? '').toString();
    final teacherId = (json['teacher_id'] ?? json['teacher']?['user_id'] ?? json['teacher']?['id'] ?? '').toString();
    return ScheduleModel(
      id: json['id'] ?? '',
      dayOfWeek: _dayFromString(json['day_of_week']),
      periodNumber: json['period_number'] ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      room: json['room'],
      classId: json['class_id'] ?? '',
      className: json['class_']?['name'],
      subjectId: subjectId,
      subjectName: json['subject']?['name'],
      teacherId: teacherId,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': _dayToString(dayOfWeek),
      'period_number': periodNumber,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'class_id': classId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
    };
  }

  static DayOfWeek _dayFromString(String? day) {
    switch (day?.toLowerCase()) {
      case 'monday':
        return DayOfWeek.monday;
      case 'tuesday':
        return DayOfWeek.tuesday;
      case 'wednesday':
        return DayOfWeek.wednesday;
      case 'thursday':
        return DayOfWeek.thursday;
      case 'friday':
        return DayOfWeek.friday;
      case 'saturday':
        return DayOfWeek.saturday;
      case 'sunday':
        return DayOfWeek.sunday;
      default:
        return DayOfWeek.monday;
    }
  }

  static String _dayToString(DayOfWeek day) {
    return day.name;
  }
}
