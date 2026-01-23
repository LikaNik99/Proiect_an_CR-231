import '../../domain/entities/student_entity.dart';
import 'user_profile_model.dart';

class StudentModel extends StudentEntity {
  StudentModel({
    required super.userId,
    super.classId,
    super.user,
    super.createdAt,
    super.updatedAt,
    super.className,
    super.schoolName,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final dynamic userJson = json['user'];


    final String? schoolId = (json['school_id']?.toString().isNotEmpty == true)
        ? json['school_id'].toString()
        : (userJson is Map ? userJson['school_id']?.toString() : null);

    final user = userJson is Map
        ? UserProfileModel.fromJson(Map<String, dynamic>.from(userJson))
        : ((json['username'] != null || json['email'] != null)
            ? UserProfileModel.fromJson({
                'id': json['user_id']?.toString(),
                'username': json['username']?.toString() ?? '',
                'email': json['email']?.toString() ?? '',
                'school_id': schoolId,
              })
            : null);

    return StudentModel(
      userId: json['user_id'].toString(),
      classId: json['class_id']?.toString(),
      user: user,
      className: json['class_name']?.toString(),
      schoolName: json['school_name']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({
    String? username,
    String? email,
    String? schoolId,
  }) {
    return {
      'user_id': userId,
      if (classId != null && classId!.isNotEmpty) 'class_id': classId,
      if (schoolId != null) 'school_id': schoolId,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
    };
  }
}