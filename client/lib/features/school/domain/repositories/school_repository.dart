import '../entities/school.dart';

abstract class SchoolRepository {
  Future<List<School>> getAllSchools(String token);

  Future<School?> getSchoolById(String id, String token);

  Future<School?> createSchool(School school, String token);

  Future<School?> updateSchool(String id, School school, String token);

  Future<bool> deleteSchool(String id, String token);
}
