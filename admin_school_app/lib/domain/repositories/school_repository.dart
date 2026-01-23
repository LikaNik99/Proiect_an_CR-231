import '../entities/school_entity.dart';

abstract class SchoolRepository {
  Future<List<SchoolEntity>> getSchools();
  Future<SchoolEntity?> getSchool(String schoolId);
  Future<SchoolEntity?> createSchool(SchoolEntity school);
  Future<SchoolEntity?> updateSchool(String schoolId, SchoolEntity school);
  Future<bool> deleteSchool(String schoolId);
}