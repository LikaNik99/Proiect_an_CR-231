import '../../entities/school_entity.dart';
import '../../repositories/school_repository.dart';

class CreateSchoolUseCase {
  final SchoolRepository repository;

  CreateSchoolUseCase(this.repository);

  Future<SchoolEntity?> call(SchoolEntity school) async {
    return await repository.createSchool(school);
  }
}