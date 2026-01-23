import 'user_profile_entity.dart';

class TeacherEntity {
  /// In server schema, teacher is identified by user_id.
  final String userId;

  final String? subject;
  final bool isDirector;
  final bool isHomeroom;
  final String? classId;
  final String? schoolId;

  /// Nested user profile (username/email) from server.
  final UserProfileEntity? user;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// UI helper: resolved school name (optional)
  final String? schoolName;

  TeacherEntity({
    required this.userId,
    this.subject,
    this.isDirector = false,
    this.isHomeroom = false,
    this.classId,
    this.schoolId,
    this.user,
    this.createdAt,
    this.updatedAt,
    this.schoolName,
  });
}