import '../../domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  UserProfileModel({
    required super.id,
    required super.username,
    required super.email,
    super.avatarUrl,
    super.schoolId,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      schoolId: json['school_id']?.toString(),
    );
  }
}
