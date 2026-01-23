class Student {
  final String? userId;
  final String username;
  final String email;
  final String? parentId;
  final String classId;
  final String schoolId;

  const Student({
    this.userId,
    required this.username,
    required this.email,
    this.parentId,
    required this.classId,
    required this.schoolId,
  });
}
