import 'package:dio/dio.dart';
import '../models/student_model.dart';
import '../../core/database/database_connection_manager.dart';
import '../../core/database/db_error_mapper.dart';
import '../../core/network/network_fallback.dart';
import 'db/student_db_data_source.dart';

class StudentDataSource {
  final Dio dio;
  final StudentDbDataSource dbDataSource;

  StudentDataSource(this.dio, DatabaseConnectionManager dbManager)
      : dbDataSource = StudentDbDataSource(dbManager);

  Future<List<StudentModel>> getStudents() async {
    try {
      final response = await dio.get('/students/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => StudentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final errObj = e is Object ? e : Exception('Unknown error');
      if (NetworkFallback.shouldFallback(errObj)) {
        try {
          return await dbDataSource.getStudents();
        } catch (dbErr) {
          throw Exception(DbErrorMapper.toUserMessage(dbErr is Object ? dbErr : Exception('Unknown DB error')));
        }
      }
      throw Exception(NetworkFallback.describe(errObj));
    }
  }

  Future<StudentModel?> getStudent(String studentId) async {
    try {
      final response = await dio.get('/students/$studentId');
      return StudentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.getStudent(studentId);
      }
      return null;
    }
  }

  Future<StudentModel?> createStudent(
    StudentModel student, {
    required String username,
    required String email,
    required String schoolId,
  }) async {
    try {
      final response = await dio.post(
        '/students/',
        data: student.toJson(username: username, email: email, schoolId: schoolId),
      );
      return StudentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.upsertStudent(
          username: username,
          email: email,
          schoolId: schoolId,
          userId: student.userId,
          classId: student.classId ?? '',
        );
      }
      return null;
    }
  }

  Future<StudentModel?> updateStudent(
    String studentId,
    StudentModel student, {
    required String username,
    required String email,
    required String schoolId,
  }) async {
    try {
      final response = await dio.put(
        '/students/$studentId',
        data: student.toJson(username: username, email: email, schoolId: schoolId),
      );
      return StudentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.upsertStudent(
          username: username,
          email: email,
          schoolId: schoolId,
          userId: student.userId,
          classId: student.classId ?? '',
        );
      }
      return null;
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    try {
      await dio.delete('/students/$studentId');
      return true;
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.deleteStudent(studentId);
      }
      return false;
    }
  }
}