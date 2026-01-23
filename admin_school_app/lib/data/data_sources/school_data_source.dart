import 'package:dio/dio.dart';
import '../models/school_model.dart';
import '../../core/database/database_connection_manager.dart';
import '../../core/database/db_error_mapper.dart';
import '../../core/network/network_fallback.dart';
import 'db/school_db_data_source.dart';

class SchoolDataSource {
  final Dio dio;
  final SchoolDbDataSource dbDataSource;

  /// Dual-mode datasource: tries API first, falls back to direct DB.
  SchoolDataSource(this.dio, DatabaseConnectionManager dbManager)
      : dbDataSource = SchoolDbDataSource(dbManager);

  Future<List<SchoolModel>> getSchools() async {
    try {
      final response = await dio.get('/schools/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => SchoolModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final errObj = e is Object ? e : Exception('Unknown error');
      if (NetworkFallback.shouldFallback(errObj)) {
        try {
          return await dbDataSource.getSchools();
        } catch (dbErr) {
          throw Exception(DbErrorMapper.toUserMessage(dbErr is Object ? dbErr : Exception('Unknown DB error')));
        }
      }
      throw Exception(NetworkFallback.describe(errObj));
    }
  }

  Future<SchoolModel?> getSchool(String schoolId) async {
    try {
      final response = await dio.get('/schools/$schoolId');
      return SchoolModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.getSchool(schoolId);
      }
      return null;
    }
  }

  Future<SchoolModel?> createSchool(SchoolModel school) async {
    try {
      final response = await dio.post('/schools/', data: school.toJson());
      return SchoolModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.createSchool(school);
      }
      return null;
    }
  }

  Future<SchoolModel?> updateSchool(String schoolId, SchoolModel school) async {
    try {
      final response = await dio.put('/schools/$schoolId', data: school.toJson());
      return SchoolModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.updateSchool(schoolId, school);
      }
      return null;
    }
  }

  Future<bool> deleteSchool(String schoolId) async {
    try {
      await dio.delete('/schools/$schoolId');
      return true;
    } catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.deleteSchool(schoolId);
      }
      return false;
    }
  }
}