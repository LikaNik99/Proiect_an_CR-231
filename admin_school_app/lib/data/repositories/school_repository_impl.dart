import '../../domain/entities/school_entity.dart';
import '../../domain/repositories/school_repository.dart';
import '../data_sources/school_data_source.dart';
import '../models/school_model.dart';

class SchoolRepositoryImpl implements SchoolRepository {
  final SchoolDataSource dataSource;

  SchoolRepositoryImpl(this.dataSource);

  @override
  Future<List<SchoolEntity>> getSchools() async {
    return await dataSource.getSchools();
  }

  @override
  Future<SchoolEntity?> getSchool(String schoolId) async {
    return await dataSource.getSchool(schoolId);
  }

  @override
  Future<SchoolEntity?> createSchool(SchoolEntity school) async {
    final model = SchoolModel(
      id: school.id,
      name: school.name,
      location: school.location,
      phone: school.phone,
      email: school.email,
      website: school.website,
      logoUrl: school.logoUrl,
      establishedYear: school.establishedYear,
      isActive: school.isActive,
    );
    return await dataSource.createSchool(model);
  }

  @override
  Future<SchoolEntity?> updateSchool(String schoolId, SchoolEntity school) async {
    final model = SchoolModel(
      id: school.id,
      name: school.name,
      location: school.location,
      phone: school.phone,
      email: school.email,
      website: school.website,
      logoUrl: school.logoUrl,
      establishedYear: school.establishedYear,
      isActive: school.isActive,
    );
    return await dataSource.updateSchool(schoolId, model);
  }

  @override
  Future<bool> deleteSchool(String schoolId) async {
    return await dataSource.deleteSchool(schoolId);
  }
}