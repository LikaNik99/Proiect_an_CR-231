import 'user_profile_entity.dart';

class StudentEntity {
  /// In server schema, student is identified by user_id.
  final String userId;

  final String? classId;
  final UserProfileEntity? user;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// UI helpers
  final String? className;
  final String? schoolName;

  StudentEntity({
    required this.userId,
    this.classId,
    this.user,
    this.createdAt,
    this.updatedAt,
    this.className,
    this.schoolName,
  });
}