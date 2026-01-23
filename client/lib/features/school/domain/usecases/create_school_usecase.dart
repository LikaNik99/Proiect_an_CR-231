import '../entities/school.dart';
import '../repositories/school_repository.dart';

class CreateSchoolUseCase {
  final SchoolRepository repository;
  CreateSchoolUseCase(this.repository);

  Future<School?> call(School school, String token) async {
    return await repository.createSchool(school, token);
  }
}
