import '../../entities/school_entity.dart';
import '../../repositories/school_repository.dart';

class GetSchoolUseCase {
  final SchoolRepository repository;

  GetSchoolUseCase(this.repository);

  Future<SchoolEntity?> call(String schoolId) async {
    return await repository.getSchool(schoolId);
  }
}