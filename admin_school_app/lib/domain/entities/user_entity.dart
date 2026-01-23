class UserEntity {
  final String username;
  final String email;
  final String role;
  final bool isActive;
  final String userId;
  final bool exists;
  final String accessToken;
  final String refreshToken;

  UserEntity({
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    required this.accessToken,
    required this.userId,
    required this.exists,
    required this.refreshToken,
  });
}
