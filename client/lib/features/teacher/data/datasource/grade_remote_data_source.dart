import 'package:dio/dio.dart';
import '../model/grade_model.dart';
import '../../../../core/network/auth_options.dart';

abstract class GradeRemoteDataSource {
  Future<List<GradeModel>> getTeacherGrades(String teacherId, String token);

  Future<List<GradeModel>> getStudentGrades(String studentId, String token);

  Future<GradeModel> createGrade(Map<String, dynamic> gradeData, String token);

  Future<GradeModel> updateGrade(String gradeId, Map<String, dynamic> gradeData,
      String token);

  Future<void> deleteGrade(String gradeId, String token);
}

class GradeRemoteDataSourceImpl implements GradeRemoteDataSource {
  final Dio dio;

  GradeRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<GradeModel>> getTeacherGrades(String teacherId,
      String token) async {
    final response = await dio.get(
      '/grades/teacher/$teacherId',
      options: AuthOptions.bearer(token),
    );
    return (response.data as List)
        .map((json) => GradeModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<GradeModel>> getStudentGrades(String studentId,
      String token) async {
    final response = await dio.get(
      '/grades/student/$studentId',
      options: AuthOptions.bearer(token),
    );
    return (response.data as List)
        .map((json) => GradeModel.fromJson(json))
        .toList();
  }

  @override
  Future<GradeModel> createGrade(Map<String, dynamic> gradeData,
      String token) async {
    final response = await dio.post(
      '/grades/',
      data: gradeData,
      options: AuthOptions.bearer(token),
    );
    return GradeModel.fromJson(response.data);
  }

  @override
  Future<GradeModel> updateGrade(String gradeId, Map<String, dynamic> gradeData,
      String token) async {
    final response = await dio.put(
      '/grades/$gradeId',
      data: gradeData,
      options: AuthOptions.bearer(token),
    );
    return GradeModel.fromJson(response.data);
  }

  @override
  Future<void> deleteGrade(String gradeId, String token) async {
    await dio.delete(
      '/grades/$gradeId',
      options: AuthOptions.bearer(token),
    );
  }
}
