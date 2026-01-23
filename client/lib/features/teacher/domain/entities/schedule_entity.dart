import 'package:equatable/equatable.dart';

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class Schedule extends Equatable {
  final String id;
  final DayOfWeek dayOfWeek;
  final int periodNumber;
  final String startTime;
  final String endTime;
  final String? room;
  final String classId;
  final String? className;
  final String subjectId;
  final String? subjectName;
  final String teacherId;
  final DateTime createdAt;

  const Schedule({
    required this.id,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.classId,
    this.className,
    required this.subjectId,
    this.subjectName,
    required this.teacherId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        dayOfWeek,
        periodNumber,
        startTime,
        endTime,
        room,
        classId,
        className,
        subjectId,
        subjectName,
        teacherId,
        createdAt,
      ];
}
