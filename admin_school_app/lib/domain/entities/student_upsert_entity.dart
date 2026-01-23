class StudentUpsertEntity {
  final String? userId;
  final String username;
  final String email;
  final String classId;
  final String schoolId;

  StudentUpsertEntity({
    this.userId,
    required this.username,
    required this.email,
    required this.classId,
    required this.schoolId,
  });
}
