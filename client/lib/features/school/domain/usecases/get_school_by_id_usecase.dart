import '../entities/school.dart';
import '../repositories/school_repository.dart';

class GetSchoolById {
  final SchoolRepository repository;

  GetSchoolById(this.repository);

  Future<School?> call(String id, String token) async {
    return await repository.getSchoolById(id, token);
  }
}
