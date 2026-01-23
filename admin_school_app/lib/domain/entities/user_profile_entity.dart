class UserProfileEntity {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? schoolId;

  UserProfileEntity({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.schoolId,
  });
}
