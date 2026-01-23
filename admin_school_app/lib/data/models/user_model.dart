import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String username;
  final String email;
  final String role;
  final bool isActive;
  final String userId;
  final bool exists;
  String accessToken;
  String refreshToken;

  UserModel({
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    required this.userId,
    required this.exists,
    required this.accessToken,
    required this.refreshToken,
  }) : super(
         username: username,
         email: email,
         role: role,
         isActive: isActive,
         userId: userId,
         exists: exists,
         accessToken: accessToken,
         refreshToken: refreshToken,
       );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isActive: json['is_active'] ?? false,
      userId: json['userId'] ?? '',
      exists: json['exists'] ?? false,
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }
}
