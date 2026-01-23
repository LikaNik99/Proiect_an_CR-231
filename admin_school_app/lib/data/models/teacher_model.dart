import '../../domain/entities/teacher_entity.dart';
import 'user_profile_model.dart';

class TeacherModel extends TeacherEntity {
  TeacherModel({
    required super.userId,
    super.subject,
    super.isDirector = false,
    super.isHomeroom = false,
    super.classId,
    super.schoolId,
    super.user,
    super.createdAt,
    super.updatedAt,
    super.schoolName,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  factory TeacherModel.fromJson(Map<String, dynamic> json) {


    final dynamic userJson = json['user'];

    final String? schoolId = (json['school_id']?.toString().isNotEmpty == true)
        ? json['school_id'].toString()
        : (userJson is Map ? userJson['school_id']?.toString() : null);

    final UserProfileModel? user = userJson is Map
        ? UserProfileModel.fromJson(Map<String, dynamic>.from(userJson))
        : ((json['username'] != null || json['email'] != null)
            ? UserProfileModel.fromJson({
                'id': json['user_id']?.toString(),
                'username': json['username']?.toString() ?? '',
                'email': json['email']?.toString() ?? '',
                'school_id': schoolId,
              })
            : null);

    return TeacherModel(
      userId: json['user_id'].toString(),
      subject: json['subject']?.toString(),
      isDirector: json['is_director'] == true,
      isHomeroom: json['is_homeroom'] == true,
      classId: json['class_id']?.toString(),
      schoolId: schoolId,
      user: user,
      schoolName: json['school_name']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  /// For create/update via admin API.
  Map<String, dynamic> toJson({String? username, String? email}) {
    return {
      'user_id': userId,
      if (subject != null) 'subject': subject,
      'is_director': isDirector,
      'is_homeroom': isHomeroom,
      if (classId != null && classId!.isNotEmpty) 'class_id': classId,
      if (schoolId != null && schoolId!.isNotEmpty) 'school_id': schoolId,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
    };
  }
}