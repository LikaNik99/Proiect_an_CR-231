import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/auth_options.dart';
import '../../../../core/services/cache_service.dart';
import '../model/teacher_model.dart';

abstract class TeacherRemoteDataSource {
  Future<TeacherModel> getCurrentTeacher(String token);
  Future<String> uploadAvatar(String userId, String token, String filePath);
  Future<List<SubjectRef>> getMySubjectsForClass(String classId, String token);
  Future<List<SchoolClass>> getMyTeachingClasses(String token);
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  final Dio dio;

  TeacherRemoteDataSourceImpl({required this.dio});

  @override
  Future<TeacherModel> getCurrentTeacher(String token) async {
    try {
      final response = await dio.get(
        '/teachers/me',
        options: AuthOptions.bearer(token),
      );


      await CacheService.cacheUser(response.data as Map<String, dynamic>);

      return TeacherModel.fromJson(response.data);
    } catch (e) {
      print("⚠️ Teacher load error: $e");


      final cachedData = CacheService.getCachedUser();
      if (cachedData != null) {
        print("📦 Server unavailable - returning cached teacher: ${cachedData['username']}");
        return TeacherModel.fromJson(cachedData);
      }

      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(String userId, String token, String filePath) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final options = Options(headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'multipart/form-data',
    });

    final response = await dio.post(
      '/users/$userId/avatar',
      data: formData,
      options: options,
    );


    final data = response.data;
    final avatarUrl = data['avatar_url'] ?? data['user']?['avatar_url'];
    return avatarUrl ?? '';
  }

  @override
  Future<List<SubjectRef>> getMySubjectsForClass(String classId, String token) async {
    print('🌐 Calling /teachers/me/classes/$classId/subjects...');
    final response = await dio.get(
      '/teachers/me/classes/$classId/subjects',
      options: AuthOptions.bearer(token),
    );

    print('📦 Response status: ${response.statusCode}');
    print('📦 Response data: ${response.data}');

    final subjects = (response.data as List)
        .map((s) => SubjectRef.fromJson(Map<String, dynamic>.from(s)))
        .toList();

    print('✅ Parsed ${subjects.length} SubjectRef objects');
    return subjects;
  }

  @override
  Future<List<SchoolClass>> getMyTeachingClasses(String token) async {
    final response = await dio.get(
      '/teachers/me/teaching-classes',
      options: AuthOptions.bearer(token),
    );

    final list = (response.data as List)
        .map((c) => SchoolClass.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    return list;
  }
}
