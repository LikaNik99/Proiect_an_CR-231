class AdminUserEntity {
  final String? id;
  final String username;
  final String email;
  final String role;
  final bool isActivated;
  final String? schoolId;
  final String? schoolName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminUserEntity({
    this.id,
    required this.username,
    required this.email,
    required this.role,
    this.isActivated = false,
    this.schoolId,
    this.schoolName,
    this.createdAt,
    this.updatedAt,
  });
}
