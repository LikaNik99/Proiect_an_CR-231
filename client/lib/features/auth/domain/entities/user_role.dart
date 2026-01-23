enum UserRole { teacher, student }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.teacher:
        return 'teacher';
      case UserRole.student:
        return 'student';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      default:
        throw Exception('Rol necunoscut: $role');
    }
  }
}
