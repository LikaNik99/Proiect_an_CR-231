import '../../entities/school_entity.dart';
import '../../repositories/school_repository.dart';

class UpdateSchoolUseCase {
  final SchoolRepository repository;

  UpdateSchoolUseCase(this.repository);

  Future<SchoolEntity?> call(String schoolId, SchoolEntity school) async {
    return await repository.updateSchool(schoolId, school);
  }
}