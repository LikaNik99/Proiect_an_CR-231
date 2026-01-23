import '../../domain/entities/student_entity.dart';

class StudentModel extends Student {
  const StudentModel({
    required super.userId,
    required super.username,
    required super.email,
    super.parentId,
    required super.classId,
    required super.schoolId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    final userId = (json['user_id'] ?? user['id'] ?? '').toString();
    final username = (user['username'] ?? user['name'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final parentId = json['parent_id']?.toString();
    final classId = (user['class_id'] ?? json['class_id'] ?? '').toString();
    final schoolId = (user['school_id'] ?? json['school_id'] ?? '').toString();

    return StudentModel(
      userId: userId.isEmpty ? null : userId,
      username: username,
      email: email,
      parentId: parentId,
      classId: classId,
      schoolId: schoolId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "email": email,
      "parent_id": parentId,
      "class_id": classId,
      "school_id": schoolId,
    };
  }
}
