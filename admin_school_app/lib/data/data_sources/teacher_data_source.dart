import 'package:dio/dio.dart';
import '../models/teacher_model.dart';
import '../../core/database/database_connection_manager.dart';
import '../../core/database/db_error_mapper.dart';
import '../../core/network/network_fallback.dart';
import 'db/teacher_db_data_source.dart';

class TeacherDataSource {
  final Dio dio;
  final TeacherDbDataSource dbDataSource;

  TeacherDataSource(this.dio, DatabaseConnectionManager dbManager)
      : dbDataSource = TeacherDbDataSource(dbManager);

  Future<List<TeacherModel>> getTeachers() async {
    try {
      final response = await dio.get('/teachers/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => TeacherModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final errObj = e is Object ? e : Exception('Unknown error');
      if (NetworkFallback.shouldFallback(errObj)) {
        try {
          return await dbDataSource.getTeachers();
        } catch (dbErr) {
          throw Exception(DbErrorMapper.toUserMessage(dbErr is Object ? dbErr : Exception('Unknown DB error')));
        }
      }
      throw Exception(NetworkFallback.describe(errObj));
    }
  }

  Future<TeacherModel?> getTeacher(String teacherId) async {
    try {
      final response = await dio.get('/teachers/$teacherId');
      return TeacherModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.getTeacher(teacherId);
      }
      return null;
    }
  }

  Future<TeacherModel?> createTeacher(TeacherModel teacher, {required String username, required String email}) async {
    try {
      final response = await dio.post(
        '/teachers/',
        data: teacher.toJson(username: username, email: email),
      );
      return TeacherModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.upsertTeacher(
          username: username,
          email: email,
          schoolId: teacher.schoolId,
          userId: teacher.userId,
          subject: teacher.subject,
          isHomeroom: teacher.isHomeroom,
          isDirector: teacher.isDirector,
          classId: teacher.classId,
        );
      }
      return null;
    }
  }

  Future<TeacherModel?> updateTeacher(
    String teacherId,
    TeacherModel teacher, {
    required String username,
    required String email,
  }) async {
    try {
      final response = await dio.put(
        '/teachers/$teacherId',
        data: teacher.toJson(username: username, email: email),
      );
      return TeacherModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.upsertTeacher(
          username: username,
          email: email,
          schoolId: teacher.schoolId,
          userId: teacher.userId,
          subject: teacher.subject,
          isHomeroom: teacher.isHomeroom,
          isDirector: teacher.isDirector,
          classId: teacher.classId,
        );
      }
      return null;
    }
  }

  Future<bool> deleteTeacher(String teacherId) async {
    try {
      await dio.delete('/teachers/$teacherId');
      return true;
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.deleteTeacher(teacherId);
      }
      return false;
    }
  }
}