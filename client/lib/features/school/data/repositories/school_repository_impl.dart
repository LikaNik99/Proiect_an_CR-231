import '../../domain/entities/school.dart';
import '../../domain/repositories/school_repository.dart';
import '../datasource/school_remote_data_source.dart';
import '../models/school_model.dart';

class SchoolRepositoryImpl implements SchoolRepository {
  final SchoolRemoteDataSource remoteDataSource;
  SchoolRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<School>> getAllSchools(String token) async {
    return await remoteDataSource.getAllSchools(token: token);
  }

  @override
  Future<School?> getSchoolById(String id, String token) async {
    return await remoteDataSource.getSchoolById(id, token: token);
  }

  @override
  Future<School?> createSchool(School school, String token) async {
    return await remoteDataSource.createSchool(SchoolModel.fromJson(school.toJson()), token: token);
  }

  @override
  Future<School?> updateSchool(String id, School school, String token) async {
    return await remoteDataSource.updateSchool(id, SchoolModel.fromJson(school.toJson()), token: token);
  }

  @override
  Future<bool> deleteSchool(String id, String token) async {
    return await remoteDataSource.deleteSchool(id, token: token);
  }
}
