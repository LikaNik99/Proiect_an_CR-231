import '../entities/school.dart';
import '../repositories/school_repository.dart';

class GetSchoolsUseCase {
  final SchoolRepository repository;

  GetSchoolsUseCase(this.repository);

  Future<List<School>> call(String token) async {
    return await repository.getAllSchools(token);
  }
}
