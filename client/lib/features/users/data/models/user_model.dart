import '../../../auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  @override
  final String username;
  @override
  final String email;
  @override
  final String role;
  @override
  final bool isActive;
  @override
  final String userId;
  @override
  String accessToken;
  @override
  String refreshToken;

  UserModel({
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  }) : super(
         username: username,
         email: email,
         role: role,
         isActive: isActive,
         userId: userId,
         accessToken: accessToken,
         refreshToken: refreshToken,
       );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isActive: json['is_active'] ?? json['is_activated'] ?? false,
      userId: json['id']?.toString() ?? json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      accessToken: json['access_token'] ?? json['accessToken'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refreshToken'] ?? '',
    );
  }
}
