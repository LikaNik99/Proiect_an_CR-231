import 'package:dio/dio.dart';
import '../model/homework_model.dart';
import '../../../../core/network/auth_options.dart';

abstract class HomeworkRemoteDataSource {
  Future<List<HomeworkModel>> getClassHomework(String classId, String token);
  Future<HomeworkModel> createHomework(Map<String, dynamic> homeworkData, String token);
  Future<HomeworkModel> updateHomework(String homeworkId, Map<String, dynamic> homeworkData, String token);
  Future<void> deleteHomework(String homeworkId, String token);
  Future<List<HomeworkModel>> createHomeworkBulk(List<Map<String, dynamic>> homeworkList, String token);
}

class HomeworkRemoteDataSourceImpl implements HomeworkRemoteDataSource {
  final Dio dio;

  HomeworkRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<HomeworkModel>> getClassHomework(String classId, String token) async {
    final response = await dio.get(
      '/homework/class/$classId',
      options: AuthOptions.bearer(token),
    );
    return (response.data as List).map((json) => HomeworkModel.fromJson(json)).toList();
  }

  @override
  Future<HomeworkModel> createHomework(Map<String, dynamic> homeworkData, String token) async {
    final response = await dio.post(
      '/homework/',
      data: homeworkData,
      options: AuthOptions.bearer(token),
    );
    return HomeworkModel.fromJson(response.data);
  }

  @override
  Future<HomeworkModel> updateHomework(String homeworkId, Map<String, dynamic> homeworkData, String token) async {
    final response = await dio.put(
      '/homework/$homeworkId',
      data: homeworkData,
      options: AuthOptions.bearer(token),
    );
    return HomeworkModel.fromJson(response.data);
  }

  @override
  Future<void> deleteHomework(String homeworkId, String token) async {
    await dio.delete(
      '/homework/$homeworkId',
      options: AuthOptions.bearer(token),
    );
  }

  @override
  Future<List<HomeworkModel>> createHomeworkBulk(List<Map<String, dynamic>> homeworkList, String token) async {
    final response = await dio.post(
      '/homework/bulk',
      data: homeworkList,
      options: AuthOptions.bearer(token),
    );
    return (response.data as List).map((json) => HomeworkModel.fromJson(json)).toList();
  }
}
