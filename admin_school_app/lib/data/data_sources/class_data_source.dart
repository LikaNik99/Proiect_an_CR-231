import 'package:dio/dio.dart';
import '../models/class_model.dart';
import '../../core/database/database_connection_manager.dart';
import '../../core/database/db_error_mapper.dart';
import '../../core/network/network_fallback.dart';
import 'db/class_db_data_source.dart';

class ClassDataSource {
  final Dio dio;
  final ClassDbDataSource dbDataSource;

  ClassDataSource(this.dio, DatabaseConnectionManager dbManager)
      : dbDataSource = ClassDbDataSource(dbManager);

  Future<List<ClassModel>> getClasses() async {
    try {
      final response = await dio.get('/classes/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => ClassModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      final errObj = e is Object ? e : Exception('Unknown error');
      if (NetworkFallback.shouldFallback(errObj)) {
        try {
          return await dbDataSource.getClasses();
        } catch (dbErr) {
          throw Exception(DbErrorMapper.toUserMessage(dbErr is Object ? dbErr : Exception('Unknown DB error')));
        }
      }
      throw Exception(NetworkFallback.describe(errObj));
    }
  }

  Future<ClassModel?> getClass(String classId) async {
    try {
      final response = await dio.get('/classes/$classId');
      return ClassModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.getClass(classId);
      }
      return null;
    }
  }

  Future<ClassModel?> createClass(ClassModel classModel) async {
    try {
      final response = await dio.post('/classes/', data: classModel.toJson());
      return ClassModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.createClass(classModel);
      }
      return null;
    }
  }

  Future<ClassModel?> updateClass(String classId, ClassModel classModel) async {
    try {
      final response = await dio.put('/classes/$classId', data: classModel.toJson());
      return ClassModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.updateClass(classId, classModel);
      }
      return null;
    }
  }

  Future<bool> deleteClass(String classId) async {
    try {
      await dio.delete('/classes/$classId');
      return true;
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.deleteClass(classId);
      }
      return false;
    }
  }
}