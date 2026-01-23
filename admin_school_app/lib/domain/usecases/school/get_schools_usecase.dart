import '../../entities/school_entity.dart';
import '../../repositories/school_repository.dart';

class GetSchoolsUseCase {
  final SchoolRepository repository;

  GetSchoolsUseCase(this.repository);

  Future<List<SchoolEntity>> call() async {
    return await repository.getSchools();
  }
}