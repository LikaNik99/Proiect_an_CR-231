import '../entities/school.dart';
import '../repositories/school_repository.dart';

class UpdateSchoolUseCase {
  final SchoolRepository repository;
  UpdateSchoolUseCase(this.repository);

  Future<School?> call(String id, School school, String token) async {
    return await repository.updateSchool(id, school, token);
  }
}
